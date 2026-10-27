# Container security

## Contents
- Review checklist
- Runtime hardening flags
- Secrets: where they actually leak
- Scanning
- Pinning without rotting
- Supply chain: SBOM, provenance, signing
- High-risk patterns to flag immediately

## Review checklist

Image:
- [ ] Final stage has no compilers, package-manager caches, source code, `.git`, tests
- [ ] Non-root `USER` with numeric UID; app code not owned by that user
- [ ] Base image tag pinned; digest pinned only if an update bot maintains it
- [ ] No secrets in `ENV`, `ARG`, `COPY`ed files, or layer history
- [ ] `.dockerignore` excludes `.env*`, keys, `.git`
- [ ] No `curl … | sh` without checksum verification (use `ADD --checksum=` or verify sha256)
- [ ] Scanner shows no fixable CRITICAL/HIGH

Runtime:
- [ ] Not `privileged`, no `/var/run/docker.sock` mount, no host `pid`/`network` mode unless justified
- [ ] `cap_drop: [ALL]`, `no-new-privileges`, `read_only` where the app allows
- [ ] Ports bound to `127.0.0.1` unless meant to be public
- [ ] Memory / pids limits set

## Runtime hardening

```bash
docker run --rm \
  --user 10001:10001 \
  --read-only --tmpfs /tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 256 --memory 512m --cpus 1 \
  --init \
  -p 127.0.0.1:8000:8000 \
  app:1.0
```

Binding a port below 1024 as non-root without capabilities fails. Listen on 8080/8000 inside the container and map it, instead of adding `NET_BIND_SERVICE`.

Rootless Docker or Podman removes the "root in container ≈ root on host" class of risk entirely — worth suggesting for shared hosts and CI runners.

## Secrets: where they actually leak

| Mechanism | Leaks via |
|---|---|
| `ENV SECRET=…` | `docker inspect`, `docker history`, every running process |
| `ARG TOKEN` + `--build-arg` | `docker history` of that stage **and** buildx SLSA provenance attestations, which record build args verbatim — including for builder stages never shipped. Public images have shipped working tokens this way. |
| `COPY .env` / `COPY . .` with secrets present | the layer, forever, even if deleted in a later layer |
| Runtime `environment:` | `docker inspect`, `/proc/*/environ`, crash dumps, error trackers |

Do this instead:

```dockerfile
# Build-time: secret is mounted for this RUN only, never stored in a layer
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
RUN --mount=type=secret,id=composer_auth,env=COMPOSER_AUTH composer install --no-dev
RUN --mount=type=ssh git clone git@github.com:org/private.git
```

```bash
docker build --secret id=npmrc,src=$HOME/.npmrc --ssh default .
docker build --secret id=composer_auth,env=COMPOSER_AUTH .
```

Runtime: compose/swarm `secrets:` (mounted at `/run/secrets/<name>`) with `*_FILE` env vars, or the orchestrator's secret store.

Auditing a published image: grep provenance for credential **patterns**, not for the arg name (the name also appears in commit messages and RUN lines embedded in the attestation):

```bash
docker buildx imagetools inspect <ref> --format '{{json .Provenance}}' \
  | grep -oE 'ghp_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{16}' | sort -u
```

If a secret was ever baked into a published image or attestation: **rotate it first**. Rebuilding does not remove it from existing tags.

## Scanning

```bash
docker scout quickview app:1.0            # Docker Desktop / CLI plugin
docker scout cves --only-fixed app:1.0
trivy image --severity HIGH,CRITICAL --ignore-unfixed app:1.0
trivy config Dockerfile                   # misconfig scan of Dockerfile/compose
grype app:1.0
```

Gate CI on *fixable* HIGH/CRITICAL, otherwise unfixable base-OS noise trains people to ignore the scanner. Rebuild images on a schedule (weekly) even without code changes so base-image patches land.

## Pinning without rotting

- Tag pin (`python:3.13-slim`): reproducible enough, gets patch rebuilds automatically on rebuild.
- Digest pin (`python:3.13-slim@sha256:…`): fully reproducible, **but frozen**. Without an update bot it accumulates CVEs while the tag gets patched. Keep the tag next to the digest so humans and bots can read it.

Renovate keeps digests fresh:

```json
{ "extends": ["config:recommended", "docker:pinDigests"] }
```

Dependabot: `package-ecosystem: docker` in `.github/dependabot.yml`.

Hardened/minimal bases (Docker Hardened Images at `dhi.io`, Chainguard, distroless) cut CVE counts drastically. DHI is free but requires `docker login dhi.io`; runtime variants have no shell, so build in the `-dev` variant and copy artifacts.

## Supply chain

```bash
docker buildx build --sbom=true --provenance=mode=max -t ghcr.io/org/app:1.0 --push .
cosign sign --yes ghcr.io/org/app@sha256:…      # keyless signing in CI (OIDC)
```

`provenance=mode=max` includes build args — another reason no secret may ever be a build arg.

## Flag immediately

- `privileged: true`, `--privileged`
- `-v /var/run/docker.sock:/var/run/docker.sock` (root on host)
- `-v /:/host` or other broad host mounts
- `network_mode: host`, `pid: host`
- `chmod 777`, `USER root` in final stage
- `curl … | sh` / `wget … | bash` in RUN
- Secrets in `ENV`, `ARG`, compose `environment:` committed to git
- Ports like `"0.0.0.0:5432:5432"` or `"6379:6379"` on a server
