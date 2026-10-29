---
name: justfile
description: Write, edit, review, debug and use justfiles for the `just` command runner. Use this skill whenever a task touches a `justfile`, `Justfile`, `.justfile` or `*.just` module, mentions `just` recipes, `just --list`, task automation, a project command runner, standardizing build/test/lint/fmt commands, migrating a Makefile or npm scripts to just, or wiring CI to call `just` — and also when working in a repo that has a justfile, because its recipes are the project's intended way to build, test and lint. Covers version-aware syntax, quoting, documentation that `--list` actually shows, safe destructive recipes, modules, CI parity, and verifying the result.
---

# Justfile

`just` is a command runner, not a build system: recipes always run when asked, there is no timestamp
tracking, and no `.PHONY`. A good justfile is the project's front door — a newcomer (human or agent)
types `just` and sees every important workflow, each with a one-line description, each safe to try.

Everything below serves that goal. Rules come with a reason so you can judge edge cases instead of
pattern-matching.

**everytime you create or work on a just file** make sure that all recipes work and dont error.

## 1. Orient before writing

Do these first, every time. They are cheap and they prevent the most common failures.

1. **Find the file.** `just` accepts `justfile`, `Justfile` and `.justfile` (any capitalization) and
   searches parent directories. Run `just --summary` to see whether one is in scope.
2. **Check the version.** `just --version`. `just` adds features quickly (options, `[default]`,
   `set lazy`, `[parallel]`, caching all landed in 2025–2026). Never use a feature newer than the
   installed version — check `references/features.md` for minimum versions. If the project pins a
   version (CI `setup-just`, `mise.toml`, `.tool-versions`, flake), target that instead.
3. **Read what exists.** `just --list` (what users see), then the file itself. Existing naming,
   section order, comment style, shell setting and module layout win over this skill's preferences.
   Consistency inside a repo matters more than any house style.
4. **Using a repo, not editing it?** Prefer its recipes over raw commands: `just test` beats guessing
   the `pytest` flags. Use `just --show <recipe>` or `just --dry-run <recipe>` to see what a recipe
   will run before running anything that could change state.

## 2. Core practices

### Make `just` with no arguments useful
The first recipe runs when `just` is called bare. Make it list recipes, not do work:

```just
# List available recipes
default:
    @just --list
```

`--list` sorts alphabetically; use `@just --list --unsorted` to keep your file's order, and add
`--list-submodules` when you have modules. Newer alternatives: `set default-list` (≥1.52) or a
`[default]` attribute on any recipe (≥1.43).
Avoid making `build` or `test` the bare default — surprise side effects on a reflexive `just`.

### Document what `--list` renders, not what the file shows
`just --list` shows **one line per recipe: the last line of the comment block directly above it**.
Verified behavior:

- A multi-line comment block lists only its final line — often an example or half a sentence.
- A blank line between comment and recipe breaks the link; the recipe lists with no description,
  and inserting a recipe between a comment and its recipe silently steals the comment.
- `{{…}}` inside comments is **not** interpolated.

So: one-line comment directly above each public recipe. If you need more lines, keep them and add
`[doc("One line summary")]` (≥1.27) — `--list` then uses that. After editing, re-run `just --list`
and read it as a newcomer would.

### Use a predictable vocabulary
People and CI should be able to type the obvious name. Use the subset that applies, with these
meanings, before inventing names:

| Recipe | Meaning |
|---|---|
| `setup` | Install deps / bootstrap a fresh clone (idempotent) |
| `dev` | Start the dev loop (server, watcher) |
| `build` | Produce artifacts |
| `test` | Run tests; accept `*args` passthrough |
| `lint` / `lint-fix` | Check / auto-fix lint |
| `fmt` / `fmt-check` | Format / verify formatting (read-only) |
| `check` | All read-only gates; what CI and pre-commit run |
| `clean` | Remove generated files |

Pair every mutating quality recipe with a read-only twin (`fmt` / `fmt-check`). `check` must only
call the read-only ones, so running it never dirties the tree. Match an existing scheme
(`format` vs `fmt`) instead if the repo already has one. Use kebab-case; prefix helpers with `_` or
mark them `[private]`.

### Remember each line is its own shell
Every recipe line is a separate shell invocation. `cd`, `export` and shell variables do not carry to
the next line — a classic silent bug:

```just
# Wrong: pwd prints the justfile directory, not dist/
deploy:
    cd dist
    ./upload.sh
```

Fix with `cd dist && ./upload.sh`, the `[working-directory("dist")]` attribute (≥1.38), or a script
recipe. Use a script recipe (shebang or `[script("bash")]` ≥1.44) whenever logic needs state,
loops, conditionals or traps, and start it with `set -euo pipefail` — script recipes do **not**
inherit `set shell` flags:

```just
# Tag and push a release
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    git diff --quiet || { echo "working tree dirty" >&2; exit 1; }
    git tag -a "v{{ version }}" -m "v{{ version }}"
    git push origin "v{{ version }}"
```

For line recipes, `set shell := ["bash", "-euo", "pipefail", "-c"]` gives fail-fast pipes per line
(default is `sh -cu`). Only set it if bash is guaranteed (not on stock Windows).

### Quote interpolations
`{{ x }}` pastes raw text into the command **before** the shell parses it. A value with a space,
quote or `$` splits or breaks the command (`just greet "a b's c"` fails with an unmatched quote).

- Wrap any parameter that can contain spaces or quotes in `quote()`: `{{ quote(path) }}`.
- For variadic passthrough, prefer `set positional-arguments` + `"$@"`, which preserves each argument
  exactly; bare `{{ args }}` only works for space-free flags.
- In recipe bodies `{{{{` produces a literal `{{`; `$` is not special to just, so `$VAR` and `"$@"`
  reach the shell untouched (no Make-style `$$`).

### Handle environment deliberately
- Use `env("NAME", "default")` (≥1.15). `env_var_or_default` is the legacy spelling — still works,
  but don't introduce it.
- `set dotenv-load` only if the project actually uses a `.env`. The file is found relative to the
  working directory just uses, not your shell's cwd. Never echo secrets; never commit `.env`.
- Check tools exist up front: `docker := require("docker")` (≥1.39) gives a clear error instead of a
  failure halfway through a recipe.

### Mind backtick cost
`` git_sha := `git rev-parse HEAD` `` runs on **every** invocation, even `just --list` and unrelated
recipes. Prefer `set lazy` (stable ≥1.48: only evaluates what is used) or compute the value inside
the recipe that needs it.

### Make destructive recipes safe and scriptable
Anything that deletes data, rewrites history, or touches shared environments gets
`[confirm("Drop the local database?")]` (≥1.17) and says so in its doc line. `[confirm]` reads the
terminal; CI passes `just --yes <recipe>` instead of piping input. Keep `clean` scoped to generated
files; put cache/venv/`node_modules` wiping in a separate `clean-all`.

`_`/`[private]` hides recipes from `--list` but they remain callable — it is tidiness, not access
control.

### Cross-platform without silent gaps
Use `[unix]`, `[linux]`, `[macos]`, `[windows]` attributes or `os()` / `os_family()` conditionals.
If no variant matches the current OS, current versions fail with "does not contain recipe" — give
every platform-split recipe a variant for each supported OS, or an explicit
`error("unsupported on " + os())` path. Don't assume bash, GNU `sed -i`, or `xargs -r` on macOS or
Windows; push complex portable logic into a Python/Node script recipe or a checked-in script.

### Split into modules only when it pays
Under ~20 recipes, one file with `# --- Section ---` comments or `[group("…")]` is clearest. Beyond
that, or with clearly separate concerns, use `mod db` (loads `db.just` or `db/mod.just`, called as
`just db migrate` or `just db::migrate`). Name modules after the concern (`db`), not the tool
(`psql`). Two traps:

- Module recipes run with the **module file's directory** as cwd. Use `source_directory()` /
  `justfile_directory()` for paths, not bare relatives.
- Settings like `set shell`, `set dotenv-load` and `set fallback` are per-file; repeat what matters.

`import 'file.just'` merges recipes into the same namespace instead — good for shared snippets.

### Keep CI and local identical
CI should call recipes (`just check`, `just build`), not duplicate their commands in YAML. Then any
CI failure reproduces locally with the same command. Every recipe must exit non-zero on failure and
must not prompt in CI (use `--yes`, defaults, or flags). Pin `just` in CI. See
`references/patterns.md` for a GitHub Actions example.

## 3. Workflows

**Create a justfile.** Orient (§1) → detect stack from manifests (`pyproject.toml`, `package.json`,
`Cargo.toml`, `go.mod`, `Dockerfile`, `.env`) → start from the closest template in
`references/patterns.md` → include only recipes whose underlying tool is actually configured
(no `lint` if there is no linter) → verify (§4).

**Edit a justfile.** Make the smallest change in the file's existing style. Do not run `just --fmt`
on a file unless the repo already uses it (`just --fmt --check` passes before your edit, or CI runs
it) — reformatting buries your change in a noisy diff. Re-check `--list` afterward for stolen or
fragment doc lines.

**Review a justfile.** Run `scripts/lint_justfile.py`, then read for what it can't judge: wrong
commands, missing `check`, unsafe destructive recipes, platform gaps, CI calling raw commands.
Report findings with the exact recipe name and a concrete fix.

**Migrate from Make / npm scripts.** Map targets to recipes one-to-one first, keep names users know
(add `alias` for renamed ones), drop `.PHONY`, replace `$(VAR)` with `{{ VAR }}`, convert
multi-line shell that relied on `\` continuations or `.ONESHELL` into script recipes. If targets
depend on file timestamps for incremental builds, keep Make for those — just won't skip work.
Details in `references/patterns.md`.

## 4. Verify before calling it done

Report the commands you ran and their outcomes.

1. **Parses:** `just --summary` (or `just --list`). Any error → fix first.
2. **Reads well:** `just --list` — every public recipe has a sensible one-line description, nothing
   internal leaks.
3. **Expands correctly:** `just --dry-run <recipe> [args]` for new/changed recipes, including an
   argument with a space in it.
4. **Runs:** execute read-only recipes (`check`, `fmt-check`, `test`) for real. For state-changing
   ones, use dry-run or the project's own `--dry-run` flag; never run deploy/release/destructive
   recipes to "test" them.
5. **Lints:** `python3 scripts/lint_justfile.py [path/to/justfile]` — structural checks via
   `just --dump --dump-format json` (missing/fragment docs, unquoted params, `cd` on its own line,
   destructive commands without `[confirm]`, eager backticks, no listing default).

Useful introspection: `just --show <r>`, `just --evaluate`, `just --usage <r>` (≥1.46),
`just --dump --dump-format json` for machine-readable structure.

## 5. Mistakes seen in the wild

| Instead of | Do |
|---|---|
| `default:` that echoes text or builds | `default: @just --list` |
| Multi-line comment, nothing else | One line, or add `[doc("…")]` |
| `cd x` on one line, command on the next | `cd x && cmd`, `[working-directory]`, or script recipe |
| `cmd {{ path }}` with user input | `cmd {{ quote(path) }}` or positional-arguments + `"$1"` |
| `cmd {{ args }}` passthrough with spaces | `set positional-arguments` + `cmd "$@"` |
| `env_var_or_default("X", "d")` in new code | `env("X", "d")` |
| Shebang recipe without `set -euo pipefail` | Add it — `set shell` flags don't apply |
| Global backtick used by one recipe | `set lazy` or compute inside the recipe |
| `rm -rf`/`DROP`/`destroy` with no guard | `[confirm("…")]`, and `--yes` in CI |
| CI YAML repeating recipe commands | CI calls `just <recipe>` |
| Features newer than installed `just` | Check `just --version` and `references/features.md` |
| `just --fmt` on someone's hand-formatted file | Leave formatting alone unless repo uses it |
| Recipe named after the tool (`cargo-build`) | Name after intent (`build`) |
| Hard-coded house style forced onto a repo | Follow the repo's conventions |

## References

- `references/features.md` — settings, attributes, functions, parameters and CLI flags, each with
  the minimum `just` version. Read when using anything beyond basic recipes, or when the installed
  version is old.
- `references/patterns.md` — starter templates (generic, Python/uv, Node/pnpm, Rust, Go, Docker),
  check/fix pairs, modules layout, GitHub Actions, Make migration table. Read when creating a
  justfile or wiring CI.
- `scripts/lint_justfile.py` — structural linter; run after creating or editing.
- Manual for anything else: `just --man` or https://just.systems/man/en/ (match installed version).
