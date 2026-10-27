---
name: docker
description: "Write, review, harden, debug and verify Dockerfiles, compose.yaml / docker-compose.yml, .dockerignore, buildx/bake and container CI. Use this skill for ANY Docker or container task — containerizing an app, shrinking an image, speeding up a slow build, fixing a container that won't start, exits immediately, ignores Ctrl+C, can't reach its database, or leaves root-owned files behind, adding healthchecks, secrets, multi-arch builds or image scanning — even when the user only says 'dockerize this', 'add a compose file', 'why is my image 2GB' or pastes a Dockerfile without naming a goal. Also use for Podman/Containerfile work, which follows the same rules."
license: MIT
compatibility: "Docker Engine 23+ with BuildKit and the Compose v2 plugin (`docker compose`). Optional: hadolint, trivy or docker scout."
metadata:
  version: "1.0.0"
---

# Docker

Build images that are small, reproducible, secure by default, and **proven to work** — not just plausible-looking.

Most Docker advice is well known (multi-stage, non-root, `.dockerignore`). The failures that actually cost people hours are the quiet ones: a container that takes 10 s to stop because PID 1 ignores SIGTERM, a healthcheck calling `curl` in an image that has no curl, a build `ARG` token sitting in published provenance, a `depends_on` that waits for a container to *start* rather than be *ready*. This skill front-loads those.

## 0. Before you write anything

1. **Read what exists.** Look for `Dockerfile*`, `Containerfile`, `compose*.y*ml`, `docker-compose*.y*ml`, `.dockerignore`, `docker-bake.hcl`, CI workflows, and the app's manifest/lockfile. Match existing conventions (base image family, user names, port, stage names) unless they are the problem.
2. **Check the toolchain:** `docker version`, `docker compose version`, `docker buildx version`. Use `docker compose` (v2). Never write `docker-compose` commands or a top-level `version:` key — both are obsolete and the key now only produces a warning.
3. **Don't trust your memory for versions.** Runtime LTS lines move (Node, Python, Go, Java, Postgres). Read the version from the project (`.nvmrc`, `engines`, `.python-version`, `go.mod`, `pom.xml`) or check the image's tags page; if you can't check, say which version you assumed.
4. **Know the target:** dev loop, CI test image, or production? Arch (Apple Silicon builds `arm64` by default — production may be `amd64`)? Orchestrator (compose, Kubernetes, ECS)? Ask only if it changes the output and you can't infer it.

## 1. Dockerfile rules (with the reason, so you can judge exceptions)

Start every Dockerfile with `# syntax=docker/dockerfile:1` — it gives you current BuildKit features (cache/secret mounts, heredocs, `COPY --link`, build checks) regardless of the engine version.

| Rule | Why |
|---|---|
| Multi-stage: build tools in `build`, only artifacts in the final stage | Compilers, dev deps and source are attack surface and size with zero runtime value. |
| Copy manifests + lockfile, install, *then* `COPY . .` | Dependency layers stay cached across code edits. Always install from the lockfile (`npm ci`, `uv sync --locked`, `pip install -r` with hashes, `go mod download`). |
| `RUN --mount=type=cache,target=<pkg cache>` | Cache survives even when the layer is invalidated; faster than any layer-ordering trick. Don't also delete that cache dir. |
| Clean package-manager state **in the same `RUN`** (`apt-get … && rm -rf /var/lib/apt/lists/*`, `apk add --no-cache`) | A later `RUN rm` cannot shrink an earlier layer. Use `--no-install-recommends` with apt. |
| Pin base images to a specific tag (`python:3.13-slim`); pin by digest (`@sha256:…`) in production **with Renovate/Dependabot updating it** | `:latest` and missing tags aren't reproducible. But an un-maintained digest pin silently freezes CVEs — a stale pin can be worse than a floating minor tag. Pin + automate updates, or don't pin by digest. |
| Run as a non-root user with a fixed numeric UID (`USER 10001` or the image's built-in `node`/`nonroot`) | Limits breakout impact; numeric UIDs let Kubernetes `runAsNonRoot` verify it. |
| Keep app files **owned by root, readable by the user** — only `chown` the dirs the app must write | If the runtime user owns its own code, a compromise can rewrite it. `COPY --chown` everything is a common over-correction. |
| Exec-form `CMD`/`ENTRYPOINT` (`["node","server.js"]`), never `npm start`/shell form for the main process | Shell form makes `/bin/sh` PID 1, which doesn't forward SIGTERM → `docker stop` waits 10 s then SIGKILLs, skipping graceful shutdown. `npm`/`yarn` wrappers have the same problem. |
| Handle PID 1: app traps SIGTERM, **or** run with `init: true` / `docker run --init` / `tini` | PID 1 gets no default signal handlers and must reap zombies. Node and many scripts don't handle this by default. |
| Entrypoint scripts end with `exec "$@"` | Otherwise the script stays PID 1 and the real process never gets signals. |
| Secrets via `RUN --mount=type=secret`, never `ARG`/`ENV` | `ENV`/`ARG` values persist in `docker history` **and** buildx records build args verbatim in SLSA provenance attestations — even from builder stages that aren't shipped. |
| `COPY` over `ADD` (use `ADD --checksum=sha256:…` only for remote files) | `ADD` auto-extracts and fetches URLs — surprising behavior. |
| `HEALTHCHECK` only with a tool that exists in the final image | `alpine`, `slim` and distroless images often lack `curl`/`wget`. Use the runtime itself (`node -e`, `python -c`), a tiny static probe binary, or define the check in compose/K8s instead. |
| Language env defaults: `PYTHONUNBUFFERED=1`, `PYTHONDONTWRITEBYTECODE=1`; `NODE_ENV=production` **only in the runtime stage** | Unbuffered logs reach `docker logs` immediately. `NODE_ENV=production` in the build stage makes `npm ci` skip devDependencies your build needs. |
| Use `npm ci --omit=dev` (not `--only=production` / `--production`, which are deprecated) | |
| Cross-arch: `FROM --platform=$BUILDPLATFORM` for the build stage + `ARG TARGETOS TARGETARCH` | Compiles natively and cross-compiles instead of running the whole build under slow QEMU emulation. |
| Add OCI labels (`org.opencontainers.image.source`, `.revision`, `.version`) | Links the image to its repo/commit in registries and scanners. |

**`.dockerignore` is mandatory.** It shrinks the build context, keeps the cache stable, and stops `.env`, keys and `.git` from leaking into `COPY . .`. For sensitive repos prefer an allowlist (`*` then `!src/` `!package*.json` …). Minimum denylist: `.git`, `.env*` (keep `!.env.example`), `*.pem`, `*.key`, `node_modules`, `.venv`, `__pycache__`, `dist`/`build`, `coverage`, `Dockerfile*`, `compose*.y*ml`, editor/OS junk. Exception: a native-module build may need files you'd normally ignore — check the build still passes.

**Base image choice:** `-slim` (Debian, glibc) is the safe default. Alpine (musl) is smaller but breaks some Python wheels and native modules and has DNS quirks — use it when you've confirmed compatibility. Distroless or `scratch` for static binaries (Go, Rust) — no shell, so debugging uses `docker debug` or an ephemeral sidecar. Docker Hardened Images (`dhi.io/…`) are now free and minimal; they require `docker login dhi.io` and the runtime variants have no shell/package manager, so build in the `-dev` variant.

Language templates (Node, Python/uv, Go, Java, static frontend): **read `references/dockerfile-templates.md`** before writing a Dockerfile for one of these.

## 2. Compose rules

- File name `compose.yaml`, top-level `name:`, **no `version:`**.
- `depends_on: { db: { condition: service_healthy, restart: true } }` **plus** a real `healthcheck` on the dependency. Plain `depends_on` only waits for the container to start, not for the DB to accept connections. Give slow starters a `start_period`.
- Publish ports on loopback unless they must be public: `"127.0.0.1:5432:5432"`. Docker's iptables rules **bypass ufw/firewalld**, so `"5432:5432"` exposes the DB to the internet on a VPS even with the firewall "on". Databases usually need no published port at all — services reach each other by service name on the compose network.
- Required config fails loudly: `${API_KEY:?API_KEY must be set}`. Defaults use `${TAG:-dev}` (`:-` covers unset **and** empty; a bare missing tag silently becomes `:latest`).
- Secrets: top-level `secrets:` + `*_FILE` env vars (most official images support `POSTGRES_PASSWORD_FILE` etc.). Never commit `.env`; commit `.env.example`.
- Named volumes for data; bind mounts for source code in dev only. Check each DB image's documented data path — e.g. `postgres:18+` expects the volume at `/var/lib/postgresql`, not `…/data`.
- Hardening for app services: `read_only: true` + `tmpfs: [/tmp]`, `cap_drop: [ALL]` (add back only what's needed), `security_opt: ["no-new-privileges:true"]`, `init: true`, `pids_limit`, memory limits.
- Logging: default `json-file` grows without limit. Set `logging: { driver: local }` or `json-file` with `max-size`/`max-file`, here or in `daemon.json`.
- Dev vs prod: base `compose.yaml` + auto-loaded `compose.override.yaml` for dev (bind mounts, debug ports) and `compose.prod.yaml` passed explicitly with `-f`. Prefer `develop.watch` (`docker compose watch`) over bind-mounting the whole repo — it avoids clobbering `node_modules` and root-owned-file problems.
- `profiles:` for optional tools (adminer, mailhog). Gotcha: `docker compose down` ignores containers of profiles that aren't enabled — use `docker compose --profile '*' down`.

Full patterns (anchors/extension fields, overlays, watch, per-database healthchecks): **`references/compose.md`**.

## 3. Verify before you say "done"

A Dockerfile that hasn't been built hasn't been written. If Docker is available, run the loop; if not, say explicitly that the output is unverified and give the user these commands.

```bash
docker build --check .                          # BuildKit lint: no build, fast
docker run --rm -i hadolint/hadolint < Dockerfile   # if available
docker compose config -q                        # compose syntax + interpolation (cp .env.example .env first in CI)
docker build -t app:verify .
bash scripts/verify_image.sh app:verify [port]  # user, size, healthcheck, shell-form CMD, env secrets, SIGTERM stop time
```

`scripts/verify_image.sh` (bundled) checks what reviews usually miss: that the image really runs non-root, has no secret-looking `ENV`, uses exec-form CMD, becomes healthy, and stops in under ~3 s on SIGTERM. For caching changes, prove the cache: edit a source file's *content* (BuildKit hashes content; `touch` is not enough) and rebuild — dependency layers must show `CACHED`.

Report image size before/after when optimizing, and which checks you couldn't run.

## 4. Safety when operating Docker for the user

- **Ask first** before anything that destroys data or state: `docker compose down -v`, `docker volume rm`, `docker system prune` (especially `-a --volumes`), `docker rm -f` on containers you didn't create.
- Don't `docker push`, `docker login`, or change `daemon.json` / contexts without being asked.
- Never print secret values (env dumps, `docker inspect` of env, `~/.docker/config.json`). Redact.
- Mounting `/var/run/docker.sock` into a container is root on the host — flag it whenever you see or add it.
- On Windows hosts with Docker Desktop (WSL2 backend), run docker commands from inside WSL with project files on the WSL filesystem; bind mounts from Windows/network drives are slow or mistranslated.
- On SELinux hosts (Fedora/RHEL), bind mounts need `:z`/`:Z` or the container gets permission denied.

## 5. Troubleshooting

Symptom → cause table (exits immediately, 10 s stops, `EACCES` on host files, `exec format error`, can't reach DB, `no such file or directory` for a file that exists, cache never hits, huge images): **`references/troubleshooting.md`**.

## References

- `references/dockerfile-templates.md` — production templates for Node, Python (uv and pip), Go, Java, static SPA; entrypoint script pattern.
- `references/compose.md` — full compose example, overlays, watch, healthchecks for Postgres/MySQL/MariaDB/Redis/Mongo, anchors, profiles.
- `references/security.md` — runtime hardening, image scanning, build-secret and provenance leaks, digest pinning with Renovate, SBOM.
- `references/ci.md` — buildx/bake, GitHub Actions with cache, multi-platform, testing images in CI.
- `references/troubleshooting.md` — symptom → cause → fix.
- `scripts/verify_image.sh` — post-build verification of an image.
