# just feature reference (version-aware)

Check `just --version` first and only use features at or below it. Versions are the release that
added (or stabilized) the feature. Everything here was checked against just 1.59; for anything
missing see `just --man` or https://just.systems/man/en/.

## Contents
1. Recipe syntax & parameters
2. Settings
3. Attributes
4. Functions & expressions
5. Modules & imports
6. CLI flags worth knowing
7. Newer / advanced (≥1.47)

## 1. Recipe syntax & parameters

```just
# One-line doc shown by --list
build target="debug" *flags: _prep (compile target) && notify
    cargo build --profile {{ target }} {{ flags }}
```

| Form | Meaning |
|---|---|
| `name:` | Recipe; body indented consistently (spaces or tabs, not mixed) |
| `name arg:` | Required positional |
| `name arg="x":` | Defaulted positional |
| `name +args:` | One or more (variadic) |
| `name *args:` | Zero or more (variadic) |
| `name $arg:` | Parameter also exported as env var `arg` |
| `a: b c` | Run `b`, `c` first (each at most once per invocation) |
| `a: (b "x")` | Dependency with arguments |
| `a: b && c` | `c` runs after `a`'s body |
| `@line` | Don't echo this line (`@name:` → whole recipe quiet; `set quiet` globally) |
| `-line` | Ignore this line's failure |
| `alias t := test` | Short name; shows in `--list` as `[alias: t]` |

**Positional arguments**: `set positional-arguments` (0.9.1) or `[positional-arguments]`
per recipe (1.29) exposes args as `$1…`/`"$@"`. This is the quoting-safe way to forward args.

**Options and flags** (1.46): parameters can be `--long` / `-s` options via `[arg]`:

```just
# Deploy the app
[arg("env", long, help="Target environment")]
[arg("force", long, value="true")]      # bare --force sets force="true"
deploy env="staging" force="false":
    ./deploy.sh {{ quote(env) }} {{ force }}
```

`just deploy --env prod --force`; `just --usage deploy` prints generated help. Variadic options
1.55; combined short options 1.55.

## 2. Settings

| Setting | Since | Notes |
|---|---|---|
| `set shell := ["bash", "-euo", "pipefail", "-c"]` | old | Line-recipe shell. Default `sh -cu`. Not used by shebang/script recipes |
| `set dotenv-load` | old | Load `.env`. Also `dotenv-filename`, `dotenv-path`, `dotenv-required` (1.28), `dotenv-override` (1.41) |
| `set export` | old | Export all variables as env vars |
| `set positional-arguments` | 0.9.1 | `$1`, `"$@"` in recipes |
| `set quiet` | old | Don't echo any lines (`[no-quiet]` opts a recipe back in) |
| `set fallback` | old | Search parent dirs for a recipe not found here; not inherited by modules |
| `set ignore-comments` | old | Don't pass `#` lines in line-recipe bodies to the shell |
| `set allow-duplicate-recipes` / `-variables` | old | Later definition wins (useful with `import`) |
| `set working-directory := "dir"` | 1.33 | Default cwd for recipes |
| `set no-exit-message` | 1.39 | Suppress just's "recipe failed" line |
| `set windows-shell` | — | **Deprecated 1.56**; use OS-conditional shells/attributes |
| `set lazy` | 1.47 (stable 1.48) | Only evaluate assignments that are used; `eager x := …` forces one |
| `set default-list` | 1.52 | Bare `just` lists recipes |
| `set default-script` / `[shell]` | 1.52 | Treat recipes as scripts by default / opt back out |
| `set no-cd` | 1.51 | Recipes run in invocation dir |
| `set lists` | 1.53 | List values; required by `which()` since 1.53 |

Settings are **per file**: modules don't inherit the parent's `shell`, `dotenv-*`, `fallback`, etc.

## 3. Attributes

Multiple attributes: stack lines or comma-separate `[private, no-cd]`.

| Attribute | Since | Use |
|---|---|---|
| `[confirm]`, `[confirm("Prompt?")]` | 1.17 | Ask before running; `just --yes` skips |
| `[doc("text")]`, `[doc]` | 1.27 | Override / suppress `--list` description |
| `[group("name")]` | 1.27 | Group in `--list`; filter with `just --list --group name` (1.47) |
| `[private]` | old | Hide from `--list` (same as `_` prefix). Still callable |
| `[no-cd]` | 1.9 | Run in invocation directory (for tools taking user-relative paths) |
| `[working-directory("dir")]` | 1.38 | Run this recipe in `dir` |
| `[linux]` `[macos]` `[unix]` `[windows]` (`[openbsd]` 1.38, BSDs 1.47) | old | Platform variants of the same recipe name |
| `[positional-arguments]` | 1.29 | Per-recipe positional args |
| `[no-exit-message]` / `[exit-message]` | old / 1.39 | Silence or force failure message |
| `[script]`, `[script("python3")]` | 1.32 unstable → **1.44 stable** | Body runs as a script file, like shebang but portable |
| `[extension(".py")]` | 1.32 | Temp-file extension for script/shebang recipes |
| `[parallel]` | 1.42 | Run this recipe's dependencies in parallel (`--jobs N`, 1.56) |
| `[metadata("k")]` | 1.42 | Arbitrary metadata, visible in JSON dump |
| `[default]` | 1.43 | Make this recipe the default instead of the first one |
| `[arg(...)]` | 1.46 | Options, flags, help, patterns for parameters |
| `[env("NAME", "value")]` | 1.47 | Set an env var for this recipe only |
| `[cache(...)]` | 1.54 | Skip recipe when inputs unchanged — read the manual before use |
| `[timestamp]` | 1.58 | Timestamp output lines |

## 4. Functions & expressions

```just
version := "1.4.0"
out     := justfile_directory() / "dist"          # `/` joins paths
target  := env("TARGET", "debug")                 # env with default (1.15)
docker  := require("docker")                      # error early if missing (1.39)
flavor  := if os() == "windows" { "win" } else if os() == "macos" { "mac" } else { "linux" }
```

| Group | Functions |
|---|---|
| Environment | `env(k)`, `env(k, default)` (1.15; prefer over legacy `env_var`, `env_var_or_default`) |
| Tools | `require(name)` (1.39), `which(name)` (needs `set lists` since 1.53), `just_executable()`, `just_version()` (1.55) |
| Paths | `justfile_directory()`, `justfile()`, `source_directory()`, `source_file()`, `invocation_directory()`, `home_directory()`, `cache_directory()`, `module_path()` (1.50), `path_exists(p)`, `absolute_path`, `parent_directory`, `file_name`, `extension`, `without_extension`, `join` / `/` |
| Platform | `os()`, `os_family()`, `arch()`, `num_cpus()` |
| Strings | `quote(s)`, `replace`, `replace_regex`, `trim`, `uppercase`, `lowercase`, `kebabcase`, `snakecase`, `split` (1.53), `len` (1.57) |
| Checks | `assert(cond, msg)`, `error(msg)`, `semver_matches(v, req)` |
| Misc | `sha256`, `sha256_file`, `blake3`, `uuid()`, `datetime(fmt)`, `datetime_utc(fmt)`, `shell(cmd, args…)`, `recipe_name()` (1.53) |
| User-defined | functions in the justfile (1.49) |

`` `cmd` `` backtick assignments run at load time on every invocation unless `set lazy`.
`` ```…``` `` and `'''…'''` are indented multi-line strings. `x"…"` shell-expanded strings expand
`~` and `$VAR` (allowed in attributes since 1.45).

## 5. Modules & imports

```just
mod db                        # db.just or db/mod.just  → just db migrate / just db::migrate
mod? local                    # optional; absent file is fine
mod infra 'ops/infra.just'    # explicit path
import 'just/common.just'     # merge into this namespace
import? 'local.just'          # optional import
```

- Modules stable since 1.31. Module recipes run in the module's directory. Use
  `source_directory()` inside a module for its own files and `justfile_directory()` for the root.
- Settings are not inherited. Variables are not shared; pass values as recipe parameters.
- Depending on submodule recipes (`build: db::migrate`) since 1.42.
- Root `default` should use `just --list --list-submodules` if you want module recipes expanded
  (`--list-submodules` requires `--list` since 1.40).

## 6. CLI flags worth knowing

| Flag | Use |
|---|---|
| `--list` / `-l`, `--summary` | Human list / names only |
| `--show r` | Print recipe source (includes doc/attributes since 1.56) |
| `--dry-run` / `-n` | Print commands without running (skips `shell()`/dotenv commands since 1.56–57) |
| `--evaluate [var]` | Print variable values |
| `--dump --dump-format json` | Whole parsed justfile as JSON — best for tooling |
| `--usage r` | Generated help for a recipe (1.46) |
| `--fmt`, `--fmt --check` | Canonical formatting; stable since 1.50 (earlier needed `--unstable`) |
| `--yes` | Auto-confirm `[confirm]` recipes |
| `-f path`, `-d dir` | Choose justfile / working directory |
| `--choose` | Interactive picker (fzf) |
| `--set var value`, `var=value` | Override variables from the command line |
| `--global-justfile` / `-g` | Use `~/.config/just/justfile` |

## 7. Newer / advanced (≥1.47)

Use only when the installed and CI-pinned versions both support them, and prefer the simpler
alternative when one exists:

- `set lazy` (1.48 stable) — cheapest fix for slow backtick variables.
- `[arg]` options/flags (1.46) — nicer UX than positional booleans.
- `[env]` (1.47) — per-recipe env without exporting globally.
- `set default-list` (1.52) — replaces the `default: @just --list` recipe.
- `[cache]` (1.54+) — content-based skipping; only when you have clear inputs/outputs and have
  read the manual's caching section. Otherwise leave incremental work to the underlying tool.
- User-defined functions (1.49), module aliases (1.55), `[timestamp]` (1.58).
