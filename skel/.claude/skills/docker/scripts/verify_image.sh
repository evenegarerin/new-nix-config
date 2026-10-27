#!/usr/bin/env bash
# verify_image.sh - post-build checks that code review usually misses.
#
# Usage: verify_image.sh IMAGE [CONTAINER_PORT] [--keep]
#
# Static checks (image config): runs as non-root, exec-form CMD/ENTRYPOINT,
#   HEALTHCHECK present, no secret-looking ENV, image size.
# Runtime checks (starts the image): stays up, becomes healthy, optional HTTP
#   reachability on CONTAINER_PORT, stops within a few seconds on SIGTERM.
#
# Exit code: number of FAILs (0 = all good). WARNs don't fail.
set -uo pipefail

IMAGE="${1:-}"; PORT="${2:-}"; KEEP="${3:-}"
[[ -z "$IMAGE" ]] && { echo "usage: $0 IMAGE [CONTAINER_PORT] [--keep]"; exit 2; }
command -v docker >/dev/null || { echo "docker not found"; exit 2; }

fails=0
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
warn() { printf '  \033[33mWARN\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fails=$((fails+1)); }
cfg()  { docker image inspect "$IMAGE" --format "$1" 2>/dev/null; }

docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "image $IMAGE not found locally"; exit 2; }
echo "== Static checks: $IMAGE"

# 1. Non-root user
user="$(cfg '{{.Config.User}}')"
case "$user" in
  ""|root|0|0:*|root:*) fail "runs as root (Config.User='${user:-<unset>}'); add USER <non-root uid>" ;;
  *) pass "runs as user '$user'" ;;
esac

# 2. Exec-form CMD / ENTRYPOINT (shell form shows up as [/bin/sh -c ...])
ep="$(cfg '{{json .Config.Entrypoint}}')"; cmd="$(cfg '{{json .Config.Cmd}}')"
if [[ "$ep" == '["/bin/sh","-c"'* || ( "$ep" == "null" && "$cmd" == '["/bin/sh","-c"'* ) ]]; then
  fail "shell-form ENTRYPOINT/CMD: /bin/sh is PID 1 and won't forward SIGTERM (ep=$ep cmd=$cmd)"
elif [[ "$cmd" =~ \"(npm|yarn|pnpm)\" && "$ep" == "null" ]]; then
  warn "CMD runs through a package manager ($cmd); run the process directly for signal handling"
else
  pass "exec-form entrypoint/cmd (ep=$ep cmd=$cmd)"
fi

# 3. Healthcheck
hc="$(cfg '{{if .Config.Healthcheck}}{{json .Config.Healthcheck.Test}}{{end}}')"
if [[ -z "$hc" || "$hc" == "null" ]]; then
  warn "no HEALTHCHECK in image (fine if compose/K8s defines one)"
else
  pass "HEALTHCHECK defined: $hc"
  for tool in curl wget; do
    if [[ "$hc" == *"$tool"* ]]; then
      if docker run --rm --entrypoint "" "$IMAGE" sh -c "command -v $tool" >/dev/null 2>&1; then :;
      else fail "healthcheck uses '$tool' but it is not available in the image"; fi
    fi
  done
fi

# 4. Secret-looking ENV values (names only are printed, never values)
leaky="$(cfg '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep -Ei '^[A-Z0-9_]*(PASSWORD|PASSWD|SECRET|TOKEN|API_?KEY|PRIVATE_?KEY|CREDENTIAL)[A-Z0-9_]*=.+' \
  | grep -Eiv '_FILE=|_PATH=|=/run/secrets/' | cut -d= -f1 | tr '\n' ' ')"
if [[ -n "$leaky" ]]; then fail "secret-looking ENV baked into image: $leaky"; else pass "no secret-looking ENV values"; fi

# 5. Size
bytes="$(cfg '{{.Size}}')"; mb=$(( bytes / 1024 / 1024 ))
if (( mb > 1000 )); then warn "image is ${mb} MB - check for build tools/dev deps in final stage"
else pass "image size ${mb} MB"; fi

# 6. Architecture (catches arm64-built images headed for amd64 servers)
pass "platform $(cfg '{{.Os}}/{{.Architecture}}')"

echo "== Runtime checks"
name="verify-$$"
pub=(); [[ -n "$PORT" ]] && pub=(-p "127.0.0.1::$PORT")
if ! docker run -d --name "$name" "${pub[@]}" "$IMAGE" >/dev/null 2>&1; then
  fail "container failed to start"; echo "== $fails failure(s)"; exit "$fails"
fi
cleanup() { [[ "$KEEP" == "--keep" ]] || docker rm -f "$name" >/dev/null 2>&1; }
trap cleanup EXIT

# 7. Stays up / becomes healthy (up to 60 s)
state=""; for _ in $(seq 1 60); do
  running="$(docker inspect -f '{{.State.Running}}' "$name")"
  state="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name")"
  [[ "$running" != "true" ]] && break
  [[ "$state" == "healthy" || "$state" == "unhealthy" ]] && break
  [[ "$state" == "none" && $_ -ge 5 ]] && break
  sleep 1
done
if [[ "$(docker inspect -f '{{.State.Running}}' "$name")" != "true" ]]; then
  fail "container exited (code $(docker inspect -f '{{.State.ExitCode}}' "$name")); last logs:"
  docker logs --tail 20 "$name" 2>&1 | sed 's/^/       /'
  echo "== $fails failure(s)"; exit "$fails"
fi
case "$state" in
  healthy) pass "container healthy" ;;
  unhealthy) fail "container unhealthy: $(docker inspect -f '{{range .State.Health.Log}}{{.Output}}{{end}}' "$name" | tail -c 300)" ;;
  none) pass "container running for 5 s (no healthcheck to wait on)" ;;
  *) warn "health still '$state' after 60 s (raise start_period?)" ;;
esac

# 8. Reachable on the port
if [[ -n "$PORT" ]] && command -v curl >/dev/null; then
  hp="$(docker port "$name" "$PORT" 2>/dev/null | head -1)"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$hp/" || true)"
  if [[ "$code" =~ ^[1-5][0-9][0-9]$ ]]; then pass "HTTP response $code on $hp"
  else warn "no HTTP response on $hp (not an HTTP service, or app binds 127.0.0.1 inside the container?)"; fi
fi

# 9. Graceful stop: SIGTERM should end it well before the 10 s SIGKILL
start=$(date +%s); docker stop -t 10 "$name" >/dev/null; secs=$(( $(date +%s) - start ))
code="$(docker inspect -f '{{.State.ExitCode}}' "$name")"
if (( secs >= 9 )); then fail "took ${secs}s to stop (exit $code): PID 1 ignores SIGTERM - use exec form, 'exec \"\$@\"', --init, or handle SIGTERM"
elif (( secs > 3 )); then warn "took ${secs}s to stop (exit $code)"
else pass "stopped in ${secs}s on SIGTERM (exit $code)"; fi

echo "== $fails failure(s)"
exit "$fails"
