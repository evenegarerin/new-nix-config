# Patterns and templates

Copy the closest template, delete recipes whose tool the project doesn't use, and adapt commands.
Keep recipe names and meanings stable; change only the commands inside them. All templates parse
with just ≥1.27 unless noted.

## Contents
1. Layout conventions
2. Generic skeleton
3. Python (uv)
4. Node (pnpm)
5. Rust
6. Go
7. Docker / Compose section
8. Modules layout
9. CI (GitHub Actions)
10. Migrating from Make / npm scripts

## 1. Layout conventions

Order sections so the file reads top-down: settings → variables → modules/imports → default →
everyday recipes → quality checks → release/deploy → helpers (`_private`). Use a short banner comment
per section; separate the banner from the next recipe's doc line with a blank line so the banner
isn't mistaken for documentation.

## 2. Generic skeleton

```just
set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List available recipes
default:
    @just --list

# --- Develop ---------------------------------------------------------

# Install dependencies and set up a fresh clone
setup:
    ./scripts/setup.sh

# Run tests (pass extra args through, e.g. `just test -k foo`)
test *args:
    ./scripts/test.sh "$@"

# --- Quality ---------------------------------------------------------

# Format code in place
fmt:
    ./scripts/fmt.sh

# Verify formatting without changing files
fmt-check:
    ./scripts/fmt.sh --check

# Run all read-only checks (used by CI)
check: fmt-check lint test

# Run linters
lint:
    ./scripts/lint.sh

# --- Housekeeping ----------------------------------------------------

# Remove build artifacts
clean:
    rm -rf dist build
```

## 3. Python (uv)

```just
set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List available recipes
default:
    @just --list

# Create the venv and install all dependency groups
setup:
    uv sync --all-groups

# Run the app locally with reload
dev:
    uv run uvicorn app.main:app --reload

# Run tests; extra args go to pytest
test *args:
    uv run pytest "$@"

# Lint
lint:
    uv run ruff check .

# Lint and apply safe fixes
lint-fix:
    uv run ruff check --fix .

# Format in place
fmt:
    uv run ruff format .

# Verify formatting
fmt-check:
    uv run ruff format --check .

# Type-check
typecheck:
    uv run mypy src

# All read-only gates (CI runs this)
check: fmt-check lint typecheck test

# Build sdist and wheel
build:
    uv build

# Remove build outputs and caches
clean:
    rm -rf dist build .pytest_cache .ruff_cache .mypy_cache
```

## 4. Node (pnpm)

```just
set positional-arguments

# List available recipes
default:
    @just --list

# Install dependencies exactly as locked
setup:
    pnpm install --frozen-lockfile

# Start dev server
dev:
    pnpm dev

# Run tests; extra args go to the runner
test *args:
    pnpm vitest run "$@"

# Lint
lint:
    pnpm eslint .

# Lint and auto-fix
lint-fix:
    pnpm eslint . --fix

# Format in place
fmt:
    pnpm prettier --write .

# Verify formatting
fmt-check:
    pnpm prettier --check .

# Type-check
typecheck:
    pnpm tsc --noEmit

# All read-only gates (CI runs this)
check: fmt-check lint typecheck test

# Production build
build:
    pnpm build

# Remove build output
clean:
    rm -rf dist .turbo coverage

# Remove build output and installed dependencies
clean-all: clean
    rm -rf node_modules
```

Thin wrappers over `package.json` scripts are fine (`pnpm run lint`) — the justfile is then the
discoverable index, and package.json stays the source of truth for JS tooling.

## 5. Rust

```just
set positional-arguments

# List available recipes
default:
    @just --list

# Build (debug by default; `just build release`)
build profile="dev":
    cargo build --profile {{ profile }}

# Run tests; extra args go to cargo test
test *args:
    cargo test --all-features "$@"

# Lint with warnings as errors
lint:
    cargo clippy --all-targets --all-features -- -D warnings

# Apply clippy fixes
lint-fix:
    cargo clippy --fix --allow-dirty --all-targets --all-features

# Format in place
fmt:
    cargo fmt --all

# Verify formatting
fmt-check:
    cargo fmt --all -- --check

# All read-only gates (CI runs this)
check: fmt-check lint test

# Remove target/
clean:
    cargo clean
```

## 6. Go

```just
set positional-arguments

bin := "bin/app"

# List available recipes
default:
    @just --list

# Build the binary
build:
    go build -o {{ bin }} ./cmd/app

# Run tests with the race detector; extra args go to go test
test *args:
    go test -race ./... "$@"

# Lint
lint:
    golangci-lint run

# Format in place
fmt:
    gofmt -w .

# Verify formatting (fails if any file needs gofmt)
fmt-check:
    test -z "$(gofmt -l .)"

# All read-only gates (CI runs this)
check: fmt-check lint test

# Remove built binaries
clean:
    rm -rf bin
```

## 7. Docker / Compose section

Add only if the project uses containers. Prefix names so they group naturally in `--list`.

```just
image := env("IMAGE", "myapp")
tag   := env("TAG", "dev")

# Build the container image
docker-build:
    docker build -t {{ image }}:{{ tag }} .

# Start services in the background
up:
    docker compose up -d

# Stop services (keeps volumes)
down:
    docker compose down

# Follow logs for one service or all (`just logs api`)
logs service="":
    docker compose logs -f {{ service }}

# DESTRUCTIVE: stop services and delete their volumes
[confirm("Delete all compose volumes? This wipes local data.")]
down-volumes:
    docker compose down -v
```

## 8. Modules layout

When the root grows past ~20 recipes or has clearly separate concerns:

```
justfile          # settings, default, everyday shortcuts, check/clean
db.just           # or db/mod.just
infra.just
```

```just
# root justfile
mod db
mod infra

# List recipes, including modules
default:
    @just --list --list-submodules

# Shortcut for the most common db task
migrate: db::migrate          # submodule dependency needs just ≥1.42
```

```just
# db.just — settings are NOT inherited, repeat what you need
set shell := ["bash", "-euo", "pipefail", "-c"]

root := source_directory()

# Apply pending migrations
migrate:
    {{ quote(root / "scripts/migrate.sh") }}

# DESTRUCTIVE: drop and recreate the local database
[confirm("Drop and recreate the LOCAL database?")]
reset:
    {{ quote(root / "scripts/reset.sh") }}
```

For just <1.42, make `migrate` call `just db migrate` in its body instead of depending on it.

## 9. CI (GitHub Actions)

CI calls recipes; it never re-implements them.

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: extractions/setup-just@v3
        with:
          just-version: "1.59.0"   # pin; match the features your justfile uses
      - run: just setup
      - run: just check
```

- Non-interactive: recipes must not prompt. Use `just --yes <recipe>` for `[confirm]` recipes that
  CI legitimately runs, or give them a flag.
- Locally reproducible: a red CI step is reproduced with the identical `just …` command.
- A `ci` recipe (`ci: setup check build`) is a good single entry point if CI does several steps.

Other CI systems: install just (package manager, `cargo install just`, `pipx install rust-just`, or
the official install script pinned to a version), then call the same recipes.

## 10. Migrating from Make / npm scripts

| Make | just |
|---|---|
| `.PHONY: test` | not needed |
| `VAR ?= x` | `VAR := env("VAR", "x")` |
| `$(VAR)` | `{{ VAR }}` |
| `$$HOME` | `$HOME` |
| `target: dep` | `target: dep` |
| `@cmd` / `-cmd` | `@cmd` / `-cmd` (same) |
| `.ONESHELL` or `\` continuation blocks | script recipe (shebang or `[script("bash")]`) |
| `make test ARGS=-v` | `test *args:` → `just test -v` |
| `$(shell git rev-parse HEAD)` | `` `git rev-parse HEAD` `` (consider `set lazy`) |
| `ifeq ($(OS),Windows_NT)` | `[windows]` / `[unix]` variants or `if os() == "windows"` |
| Pattern/file targets (`%.o: %.c`) | keep in Make, or call `make` from a recipe |

Steps: list every target with what it does → port one-to-one keeping names (add `alias` when
renaming) → run old and new side by side (`make -n x` vs `just --dry-run x`) → update README and CI →
delete the Makefile only when nothing references it.

npm scripts: `"lint": "eslint ."` → a `lint` recipe calling `pnpm eslint .` or `pnpm run lint`.
Keep lifecycle scripts (`prepare`, `postinstall`) in package.json — package managers run those,
not just.
