#!/usr/bin/env python3
"""Structural lint for justfiles.

Uses `just --dump --dump-format json` so it sees exactly what just parsed (modules included)
instead of re-parsing the file with regexes. It checks things that are easy to get wrong and
cheap to detect; it cannot tell whether a command is the *right* command.

Usage:
    python3 lint_justfile.py [path/to/justfile] [--strict]

Exit code: 1 if any ERROR (or any WARN with --strict), else 0.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys

DESTRUCTIVE_BODY = re.compile(
    r"rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r|\bdrop\s+(database|table|schema)\b|"
    r"terraform\s+destroy|kubectl\s+delete|docker\s+(system|volume)\s+prune|"
    r"compose\s+down\s+.*-v\b|git\s+push\s+.*--force|git\s+reset\s+--hard|helm\s+uninstall",
    re.IGNORECASE,
)
DESTRUCTIVE_NAME = re.compile(r"(^|[-_])(nuke|destroy|drop|wipe|purge|reset|teardown)([-_]|$)")
FRAGMENT_DOC = re.compile(r"^(just\s|\$\s|e\.g\.|eg\b|and\b|or\b|but\b|then\b|-\s|\*\s)|[,:;(]$", re.I)

findings: list[tuple[str, str, str]] = []


def add(level: str, where: str, msg: str) -> None:
    findings.append((level, where, msg))


def text_of(line: list) -> str:
    """Render a body line (fragments + interpolations) to approximate text."""
    out = []
    for frag in line:
        out.append(frag if isinstance(frag, str) else "{{…}}")
    return "".join(out)


def walk_expr(expr, found: list) -> None:
    """Collect variable names interpolated *without* a quote() wrapper."""
    if not isinstance(expr, list) or not expr:
        return
    head = expr[0]
    if head == "variable":
        found.append(expr[1])
    elif head == "call" and len(expr) > 1 and expr[1] == "quote":
        return  # quoted: fine
    else:
        for part in expr[1:]:
            walk_expr(part, found)


def is_script(recipe: dict) -> bool:
    if recipe.get("shebang"):
        return True
    return any(isinstance(a, dict) and "script" in a for a in recipe.get("attributes", []))


def attr_names(recipe: dict) -> set[str]:
    names = set()
    for a in recipe.get("attributes", []):
        names.update(a.keys() if isinstance(a, dict) else [a])
    return names


def lint_module(mod: dict, prefix: str, is_root: bool) -> None:
    settings = mod.get("settings", {}) or {}
    recipes: dict = mod.get("recipes", {}) or {}

    for w in mod.get("warnings", []) or []:
        add("WARN", prefix or "(root)", f"just warning: {w}")

    # Default behaviour
    if is_root and recipes and not settings.get("default_list"):
        first = mod.get("first")
        has_default_attr = any("default" in attr_names(r) for r in recipes.values())
        first_body = " ".join(text_of(l) for l in recipes.get(first, {}).get("body", []))
        if not has_default_attr and "--list" not in first_body and "--choose" not in first_body:
            add("INFO", first or "(root)",
                "bare `just` runs this recipe; consider `default: @just --list` so it lists instead")

    # Eager backticks
    if not settings.get("lazy"):
        for name, a in (mod.get("assignments") or {}).items():
            v = a.get("value")
            if isinstance(v, list) and v and v[0] == "evaluate":
                add("INFO", f"{prefix}{name}",
                    "backtick runs on every invocation (even --list); use `set lazy` (≥1.48) "
                    "or compute it inside the recipe that needs it")

    for name, r in recipes.items():
        where = f"{prefix}{name}"
        public = not r.get("private") and not name.startswith("_")
        attrs = attr_names(r)
        body = r.get("body", []) or []
        lines = [text_of(l).strip() for l in body]
        script = is_script(r)

        # Documentation as rendered by --list
        doc = r.get("doc")
        if public and not doc and "doc" not in attrs:
            add("WARN", where, "no description in `just --list`; add a one-line comment directly above it")
        elif public and doc and FRAGMENT_DOC.search(doc.strip()):
            add("WARN", where, f"--list shows a fragment ({doc!r}); add [doc(\"…\")] with a real summary")

        # Unquoted parameter interpolation
        params = {p["name"]: p for p in r.get("parameters", [])}
        flagged = set()
        for line in body:
            for frag in line:
                if isinstance(frag, list):
                    found: list = []
                    for e in frag:
                        walk_expr(e, found)
                    for v in found:
                        p = params.get(v)
                        if not p or v in flagged or p.get("flag"):
                            continue
                        flagged.add(v)
                        if p.get("kind") in ("star", "plus"):
                            add("INFO", where,
                                f"variadic `{v}` interpolated bare: args with spaces will split; "
                                "prefer positional-arguments + \"$@\"")
                        else:
                            add("INFO", where,
                                f"`{{{{ {v} }}}}` is unquoted; use `{{{{ quote({v}) }}}}` if it can contain spaces/quotes")

        # cd on its own line in a line recipe
        if not script:
            for i, t in enumerate(lines[:-1]):
                bare = t.lstrip("@-").strip()
                if re.match(r"^cd\s+\S+\s*$", bare):
                    add("WARN", where,
                        f"line {i + 1} `{bare}` does not affect later lines (each line is a new shell); "
                        "use `cd x && …`, [working-directory], or a script recipe")

        # Shebang/script without strict mode
        if script and r.get("shebang") and lines and re.search(r"\b(ba|z)?sh\b", lines[0]):
            if not any("set -e" in t or "set -euo" in t for t in lines[1:4]):
                add("WARN", where, "shell script recipe without `set -euo pipefail`; errors won't stop it")

        # Destructive without confirm
        joined = "\n".join(lines)
        if ("confirm" not in attrs) and (DESTRUCTIVE_BODY.search(joined) or DESTRUCTIVE_NAME.search(name)):
            if not re.fullmatch(r"clean(-all)?", name):
                add("WARN", where, "looks destructive but has no [confirm(\"…\")]; CI can pass --yes")

        # Legacy env function
        if "env_var_or_default" in json.dumps(body):
            add("INFO", where, "env_var_or_default is legacy; prefer env(\"NAME\", \"default\")")

    for name, a in (mod.get("assignments") or {}).items():
        if "env_var_or_default" in json.dumps(a.get("value")):
            add("INFO", f"{prefix}{name}", "env_var_or_default is legacy; prefer env(\"NAME\", \"default\")")

    for sub_name, sub in (mod.get("modules") or {}).items():
        lint_module(sub, f"{prefix}{sub_name}::", False)


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    strict = "--strict" in sys.argv
    if not shutil.which("just"):
        print("ERROR: `just` not found on PATH (pip install rust-just, brew install just, cargo install just)")
        return 1

    cmd = ["just"] + (["--justfile", args[0]] if args else []) + ["--dump", "--dump-format", "json"]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print("ERROR: justfile does not parse:\n" + proc.stderr.strip())
        return 1
    data = json.loads(proc.stdout)
    lint_module(data, "", True)

    order = {"ERROR": 0, "WARN": 1, "INFO": 2}
    findings.sort(key=lambda f: (order[f[0]], f[1]))
    for level, where, msg in findings:
        print(f"{level:5} {where}: {msg}")
    counts = {k: sum(1 for f in findings if f[0] == k) for k in order}
    print(f"\n{counts['ERROR']} error(s), {counts['WARN']} warning(s), {counts['INFO']} note(s)")
    if not findings:
        print("OK: no structural issues found. Still review commands and run `just --list` yourself.")
    failed = counts["ERROR"] > 0 or (strict and counts["WARN"] > 0)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
