# Dockerfile templates

Adapt, don't paste blindly: replace versions with the ones the project uses, the entrypoint with the real one, and the port with the real port. Each template is annotated with the non-obvious decisions.

## Contents
- Node.js (compiled TS / bundled)
- Python with uv
- Python with pip
- Go (static binary, multi-arch)
- Java (Spring Boot / any fat jar)
- Static frontend (SPA) served by unprivileged nginx
- Entrypoint script pattern
- Dev-stage pattern (one Dockerfile, several targets)

---

## Node.js

```dockerfile
# syntax=docker/dockerfile:1
ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-slim AS base
WORKDIR /app

# Production-only dependencies
FROM base AS deps
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# Full install + build (NODE_ENV not set here, so devDependencies install)
FROM base AS build
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM base AS runtime
ENV NODE_ENV=production
# Root-owned, world-readable: the app can read its code but not rewrite it
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
USER node
EXPOSE 3000
# No curl in -slim: probe with node itself (fetch is built into Node 18+)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
# Exec form, node directly (not `npm start`) so SIGTERM reaches the app.
# Node as PID 1 does not exit on SIGTERM unless the app handles it: run with
# `init: true` / `--init`, or add process.on('SIGTERM', ...) in the app.
CMD ["node", "dist/server.js"]
```

Notes:
- pnpm: `RUN corepack enable` then `pnpm install --frozen-lockfile`, cache target `/root/.local/share/pnpm/store`. Yarn berry: `yarn install --immutable`.
- Next.js: set `output: 'standalone'` and copy `.next/standalone`, `.next/static`, `public` — much smaller than shipping `node_modules`.
- Native modules (bcrypt, sharp) on Alpine need build tools and musl-compatible binaries; prefer `-slim` unless you've verified.
- If the app writes files, create only that directory writable: `RUN mkdir -p /app/uploads && chown node:node /app/uploads` (before `USER`).

## Python with uv

```dockerfile
# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-slim AS build
# Pin uv to a specific release (check current one); never :latest
COPY --from=ghcr.io/astral-sh/uv:0.9 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0
WORKDIR /app
# Dependencies only — cached until pyproject/uv.lock change
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-editable

FROM python:${PYTHON_VERSION}-slim AS runtime
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home app
WORKDIR /app
# The venv path MUST be identical in both stages: venvs hard-code absolute paths
COPY --from=build /app /app
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status==200 else 1)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Notes:
- Base image and build image must have the same Python minor version and libc (both `-slim`), or compiled wheels break.
- Gunicorn: `CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "app.main:app"]`. Gunicorn handles SIGTERM correctly as PID 1.
- Django: run `collectstatic` in the build stage; never run migrations in `CMD` of a multi-replica service — use a one-off job/`docker compose run`.

## Python with pip

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.13-slim AS build
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt

FROM python:3.13-slim
RUN useradd --system --uid 10001 --no-create-home app
COPY --from=build /opt/venv /opt/venv
WORKDIR /app
COPY . .
ENV PATH="/opt/venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
USER 10001
CMD ["python", "-m", "app"]
```

If packages need compilers (`psycopg` without binary, `numpy` on unusual arches), install `build-essential` in the **build** stage only and copy the venv.

## Go (static, multi-arch, cross-compiled)

```dockerfile
# syntax=docker/dockerfile:1
# Build stage runs on the build host's arch and cross-compiles: no QEMU
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/app

FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```

Notes:
- Distroless has no shell, so `HEALTHCHECK CMD-SHELL` can't work. Build a `healthcheck` subcommand into the binary (`ENTRYPOINT ["/app"]`, `HEALTHCHECK CMD ["/app","healthcheck"]`) or check from the orchestrator.
- `scratch` needs CA certs and tzdata copied in if the app makes TLS calls or uses time zones; distroless/static already has them.
- If CGO is required, use `gcr.io/distroless/base` (glibc) and drop `CGO_ENABLED=0`.

## Java (fat jar)

```dockerfile
# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q dependency:go-offline
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q package -DskipTests \
 && cp target/*.jar /app.jar

FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 app
COPY --from=build /app.jar /app/app.jar
USER 10001
# JVM is container-aware; size heap from the container limit, not host RAM
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

Spring Boot: layered jars (`java -Djarmode=tools -jar app.jar extract --layers`) give separate cache layers for dependencies vs application code — worth it when images are pushed often. Check the project's Java version before picking the tag.

## Static frontend (SPA)

```dockerfile
# syntax=docker/dockerfile:1
FROM node:24-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

# Unprivileged variant: runs as non-root, listens on 8080 (not 80)
FROM nginxinc/nginx-unprivileged:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
```

Minimal `nginx.conf` for client-side routing:

```nginx
server {
  listen 8080;
  root /usr/share/nginx/html;
  location / { try_files $uri $uri/ /index.html; }
  location /assets/ { expires 1y; add_header Cache-Control "public, immutable"; }
}
```

Build-time env vars (`VITE_*`, `NEXT_PUBLIC_*`) are baked into the JS bundle and are public. Never pass secrets that way.

## Entrypoint script pattern

Use only when the container needs runtime setup (templating config, waiting on a file). Keep it tiny.

```sh
#!/bin/sh
set -eu
# ... setup that must happen at runtime ...
exec "$@"     # hand PID 1 to the real process so it receives signals
```

```dockerfile
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "dist/server.js"]
```

Gotchas: a script saved with CRLF line endings fails with `no such file or directory` (add `*.sh text eol=lf` to `.gitattributes`); busybox `sh` on Alpine is not bash — no arrays, no `[[ ]]`.

## Dev-stage pattern

One Dockerfile, several targets, so dev and prod share the dependency layers:

```dockerfile
FROM base AS dev
COPY package.json package-lock.json ./
RUN npm ci
CMD ["npm", "run", "dev"]        # fine in dev; signal handling matters less
```

```yaml
services:
  app:
    build: { context: ., target: dev }
```

Keep heavy dev-only tooling (debuggers, browsers for e2e) in a stage that is `FROM base`, not `FROM` the stage that does `COPY . .` — otherwise every source edit rebuilds the tooling, and a `production` stage must never inherit from it.
