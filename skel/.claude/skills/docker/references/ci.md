# CI, buildx and bake

## Contents
- GitHub Actions: build, cache, multi-arch, push
- Testing images in CI
- Bake for several images
- Multi-platform notes

## GitHub Actions

```yaml
name: image
on:
  push: { branches: [main], tags: ["v*"] }
  pull_request:
  schedule: [{ cron: "0 4 * * 1" }]     # weekly rebuild picks up base-image patches

permissions:
  contents: read
  packages: write
  id-token: write                         # keyless signing / attestations

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # Pin third-party actions to a full commit SHA in real workflows
      - uses: actions/checkout@v5
      - uses: docker/setup-qemu-action@v3      # only needed for non-native platforms
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        if: github.event_name != 'pull_request'
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha
      - uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: mode=max
          secrets: |
            npmrc=${{ secrets.NPMRC }}
```

Notes:
- Action major versions above were current at time of writing — check for newer ones and pin to SHAs (tag-pinned actions have been hijacked in supply-chain attacks).
- `metadata-action` generates OCI labels (source, revision) automatically.
- Scheduled rebuilds should not reuse stale layers for the OS: pass `no-cache: true` or `pull: true` on the schedule trigger.
- Build secrets go through `secrets:`, never `build-args:` (provenance records build args).

## Testing images in CI

```bash
# Lint
docker build --check .
docker run --rm -i hadolint/hadolint < Dockerfile

# Smoke test: does it start, become healthy, answer, and stop cleanly?
docker build -t app:ci .
bash scripts/verify_image.sh app:ci 8000

# Full stack
cp .env.example .env
docker compose up -d --wait --wait-timeout 120
docker compose exec -T api npm test
docker compose logs --no-color > compose.log || true
docker compose down -v                   # safe here: ephemeral CI volumes
```

Gotchas:
- `docker compose config` fails in CI on `${VAR:?}` if no `.env` exists — copy `.env.example` first.
- Test a binary without running the image's entrypoint: `docker run --rm --entrypoint python app:ci --version`.
- Test an nginx config that references upstreams that don't exist in CI: `docker run --rm --add-host api:127.0.0.1 web:ci nginx -t`.
- `-T` on `compose exec` in CI (no TTY available).
- A `timeout` wrapped around `docker compose run` kills the CLI, not the container — clean up with `docker compose down`.
- Secret scanners will flag `.env.example` and docs; exclude them explicitly rather than weakening rules.

## Bake (several images / targets)

```hcl
# docker-bake.hcl
variable "TAG" { default = "dev" }

group "default" { targets = ["api", "worker"] }

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = { "org.opencontainers.image.source" = "https://github.com/acme/shop" }
}

target "api" {
  inherits = ["_common"]
  target   = "runtime"
  tags     = ["ghcr.io/acme/shop-api:${TAG}"]
}

target "worker" {
  inherits   = ["_common"]
  dockerfile = "worker.Dockerfile"
  tags       = ["ghcr.io/acme/shop-worker:${TAG}"]
  secret     = ["type=env,id=npmrc,env=NPMRC"]
}
```

`docker buildx bake --print` shows the resolved config; `docker buildx bake --push`. If a compose file sits next to the bake file, pass `-f docker-bake.hcl` explicitly — bake reads compose files by default too.

## Multi-platform notes

- On Apple Silicon, local builds are `linux/arm64`. Pushing that to an amd64 server gives `exec format error`. Use `--platform linux/amd64` or build multi-arch.
- Emulated (QEMU) builds of compiled languages are 5–20× slower. Cross-compile with `FROM --platform=$BUILDPLATFORM` + `TARGETOS/TARGETARCH` (Go, Rust, .NET, Node bundling all support this), or use native arm64 runners.
- Multi-arch images can't be `--load`ed into the classic image store; push them, or enable the containerd image store in Docker Desktop.
- Verify: `docker buildx imagetools inspect ghcr.io/acme/shop-api:1.0` lists every platform.
