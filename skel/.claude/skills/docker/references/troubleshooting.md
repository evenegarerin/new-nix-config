# Troubleshooting: symptom → cause → fix

Start with evidence, not guesses:

```bash
docker compose ps -a                         # state + exit codes
docker logs --tail 100 <c>
docker inspect <c> --format '{{.State.ExitCode}} {{.State.OOMKilled}} {{json .State.Health}}'
docker image inspect <img> --format '{{.Config.User}} {{json .Config.Entrypoint}} {{json .Config.Cmd}}'
docker run --rm -it --entrypoint sh <img>    # look inside (if it has a shell)
docker debug <c>                             # shell into distroless/slim containers (Docker Desktop / Pro)
```

| Symptom | Likely cause | Fix |
|---|---|---|
| Container exits immediately, code 0 | Main process daemonizes or the CMD is a one-shot command | Run in foreground (`nginx -g 'daemon off;'`, no `&`, no `service start`) |
| Exit code 137 | SIGKILL: OOM (`OOMKilled: true`) or stop timeout | Raise memory limit / fix leak; if from `docker stop`, see next row |
| `docker stop` / Ctrl+C takes 10 s | PID 1 is a shell, `npm`, or a process without a SIGTERM handler | Exec-form CMD, `exec "$@"` in entrypoint, `init: true`, handle SIGTERM in app |
| `exec /app/start.sh: no such file or directory` but the file exists | CRLF line endings in the script, or the shebang interpreter (`bash`) isn't in the image, or binary linked against glibc on Alpine | `.gitattributes` `*.sh text eol=lf`; use `#!/bin/sh`; use `-slim` or static build |
| `exec format error` | Image arch ≠ host arch (arm64 Mac → amd64 server) | `--platform linux/amd64` or multi-arch build |
| App can't reach DB on `localhost` | `localhost` inside a container is the container itself | Use the service name (`db:5432`) |
| Container can't reach a service on the host | Same reason | `host.docker.internal` (add `extra_hosts: ["host.docker.internal:host-gateway"]` on Linux) |
| Works on first `up`, fails with "connection refused" to DB | `depends_on` without `condition: service_healthy`, or app connects once and never retries | Healthcheck + condition; add retry/backoff in app |
| DB "ready" but tables missing / auth fails during first boot | Temporary init server (MySQL/MariaDB/Postgres) answered the readiness check | TCP-based healthcheck, generous `start_period`; verify the seed, not the log line |
| Env var change has no effect | `docker compose restart` doesn't re-read config | `docker compose up -d` (recreates changed services) |
| Code change not in container | Image not rebuilt, or bind mount masking | `docker compose up -d --build`; check `volumes:` |
| `node_modules` missing in container with bind mount | Host bind mount of the repo hides the image's `/app/node_modules` | Anonymous volume `- /app/node_modules`, or `develop.watch` |
| Host gets `EACCES` / can't delete `node_modules`, `dist`, lockfile after a container run | Container ran as root and wrote into a bind mount → root-owned files on host | Fix ownership with a throwaway container: `docker run --rm -v "$PWD:/w" alpine chown -R "$(id -u):$(id -g)" /w`; prevent with `user: "${UID}:${GID}"` |
| `permission denied` writing inside container after adding `USER` | Target dir owned by root | `mkdir` + `chown` that one dir before `USER`, or mount a volume/tmpfs there |
| `permission denied` on bind mount on Fedora/RHEL | SELinux label | `:z` (shared) or `:Z` (private) on the mount |
| Named volume ignores new files from the image | Volumes are only seeded from the image when first created | Remove the volume (ask first, data loss) or don't store image content in volumes |
| Every build reinstalls dependencies | `COPY . .` before install; `.dockerignore` missing so context changes; `ARG` with changing value declared early | Manifests first; `.dockerignore`; move `ARG` to just before use; cache mounts |
| "Sending build context" is huge / slow | No `.dockerignore` (`.git`, `node_modules`) | Add one; consider allowlist |
| Image is huge | Single stage; dev deps; caches deleted in a separate `RUN` | Multi-stage, slim base, clean in same `RUN`; inspect with `docker history` or `dive` |
| Healthcheck always `unhealthy`, app works | Probe tool (`curl`/`wget`) missing, or probing `localhost` resolving to IPv6 `::1` while app binds IPv4 | Use the runtime for the probe; probe `127.0.0.1` |
| App unreachable from host though container runs | App listens on `127.0.0.1` inside the container | Bind to `0.0.0.0` inside; restrict on the host side with `127.0.0.1:port:port` |
| Port exposed to internet despite ufw | Docker writes iptables rules before ufw's | Bind to `127.0.0.1`, or use `DOCKER-USER` chain rules |
| Disk full on host | Unbounded json-file logs, dangling images, build cache | `logging: local` or `max-size`; `docker system df`; prune **after asking** |
| Stale containers keep running after removing a profile service | `down` ignores inactive profiles | `docker compose --profile '*' down` |
| Python output appears late / not at all in logs | stdout buffering | `PYTHONUNBUFFERED=1` |
| Windows: bind mount shows an empty dir / "is a directory" error | Docker run from a Windows shell on a network/Windows drive with WSL2 backend | Run docker from inside WSL with files on the WSL filesystem |
