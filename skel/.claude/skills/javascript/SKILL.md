---
name: writing-javascript
description: Writes, edits, reviews and debugs JavaScript and Node.js code so that it fits the project it lives in and is verified before being called done. Use this skill whenever a task touches .js, .mjs, .cjs or .jsx files, package.json, npm/pnpm/yarn/bun scripts, Node.js services or CLIs, browser scripts, async/Promise code, or JS tests (Vitest, Jest, node:test, Mocha) — including bug fixes, refactors, code review, "modernize this", and "why does this behave weirdly", even if the user never says "JavaScript". For React-specific or TypeScript-type-level work, use this alongside a React or TypeScript skill if one is available.
---

# Writing JavaScript

You already know the language. This skill is about the parts that go wrong in practice:
fitting the existing project instead of imposing a style, a short list of traps that
produce plausible-looking but broken code, and proving the change works.

## Workflow

1. **Detect the project before writing code.** Run the detector (no dependencies, read-only):

   ```bash
   node <this-skill-dir>/scripts/detect-project.mjs [project-dir]
   ```

   It reports package manager, module system, target Node version, browser targets,
   test/lint/format tooling, the exact scripts to run, and whether this is a monorepo.
   If Node isn't available, read `package.json`, the lockfile and config files by hand.

2. **Follow what you found, not your defaults.** The project's choices win over this skill's
   preferences. See "Fit the project" below.

3. **Make the smallest change that solves the task.** Don't reformat, rename, convert
   CJS→ESM, swap test frameworks or add dependencies as a side effect. If something nearby
   is genuinely wrong, mention it instead of silently fixing it.

4. **Check the change against the traps list** below. Load a reference file when the task is
   in its area (table at the end).

5. **Verify.** See "Done means verified". Report what you ran and what you couldn't run.

## Fit the project

- **Package manager:** use the one the lockfile says (`pnpm add`, not `npm install`, in a
  pnpm repo). Mixing creates a second lockfile and drifts versions. In a monorepo, add the
  dependency to the right workspace package, not the root.
- **Module system:** `"type": "module"` or `.mjs` → ESM; otherwise `.js` is CommonJS. Write
  new files in the style of their neighbours. Never mix `require` and `import` in one file.
- **Runtime target:** the detector's `node` range / `.nvmrc` and `browserslist` define what
  syntax and APIs you may use. A newer API in a library that targets Node 18 breaks users.
  `references/node-and-modules.md` has a feature→version table.
- **Tooling:** use the existing test runner, assertion style, lint config and formatter.
  If a formatter exists, run it on files you touched instead of hand-formatting.
- **Conventions:** match naming, file layout, error style, logging (the project's logger,
  not `console.log`), and whether the codebase uses classes or plain functions.
- **Dependencies:** prefer what the platform already ships (`fetch`, `structuredClone`,
  `crypto.randomUUID()`, `node:test`, `AbortSignal.timeout`, `Intl`, `util.parseArgs`)
  over adding a package. If a dependency really is needed, say why and pin it with the
  project's package manager.

## Traps that look right but aren't

These are the mistakes that pass a quick read and fail in production. Check every change
against the ones that apply.

**Async**
- `array.forEach(async …)` does not wait. Use `for…of` with `await` (sequential) or
  `Promise.all(array.map(…))` (parallel).
- Independent awaits in a row are a waterfall. Start them together with `Promise.all`.
- `Promise.all` over thousands of items opens thousands of sockets/handles at once.
  Bound the concurrency (helper in `references/async-and-errors.md`).
- Every promise must be awaited, returned, or explicitly handled. A floating promise's
  rejection crashes Node (unhandled rejection) or vanishes silently.
- `Promise.race` against a `setTimeout` leaves the timer running and the work continuing.
  Prefer `AbortSignal.timeout(ms)` passed into the operation so it is actually cancelled.
- `fetch` resolves on HTTP 404/500. Check `res.ok` before reading the body.

**Errors**
- Throw `Error` objects, never strings. When wrapping, keep the original:
  `throw new Error('Loading config failed', { cause: err })`.
- Don't catch just to log and rethrow at every layer, and never swallow with an empty
  `catch`. Handle an error where you can do something useful about it.
- In `catch (err)`, `err` can be anything. Don't assume `err.message` exists on values
  from third-party code.

**Values and data**
- `??` vs `||`: `count || 10` replaces a legitimate `0`. Use `??` for defaults.
- `[10, 9, 1].sort()` → `[1, 10, 9]`. Always pass a comparator for numbers; use
  `toSorted()` (Node 20+) if mutation of the original is unwanted.
- Money and exact decimals: integers in minor units (cents) or `BigInt`, formatted with
  `Intl.NumberFormat`. Never accumulate floats.
- Dates: `new Date('2026-10-27')` is UTC midnight, `new Date('2026-10-27T00:00')` is local.
  Months are 0-based. Use `Intl.DateTimeFormat` for display and keep storage in UTC/ISO.
- `JSON.stringify` drops `undefined` and functions, throws on `BigInt` and cycles, and turns
  `Date` into a string that does not parse back into a `Date`.
- Spread and `Object.assign` are shallow. Use `structuredClone` for a deep copy of plain data.
- `parseInt('08abc')` returns 8. Validate input with `Number(x)` + `Number.isFinite`, or
  a schema validator if the project has one.

**Resources and memory**
- Every `addEventListener`, `setInterval`, subscription or open handle needs a cleanup path.
  Passing `{ signal }` from an `AbortController` to `addEventListener` makes cleanup one call.
- Module-level caches/maps that grow per request are memory leaks. Bound them or use `WeakMap`.
- In Node, stream with `pipeline` from `node:stream/promises` instead of `.pipe()` chains,
  so errors and cleanup propagate.

**Security** (details in `references/security.md`)
- No `innerHTML`/`outerHTML`/`insertAdjacentHTML` with untrusted data — use `textContent`
  or the framework's escaping.
- No `child_process.exec` with interpolated strings — use `execFile`/`spawn` with an args array.
- File paths built from user input must be resolved and checked to stay inside a base dir.
- Merging untrusted JSON into objects can pollute prototypes; validate shape, or use `Map`
  or `Object.create(null)`.
- Never `eval` / `new Function` on input; never log secrets or tokens.

## Code style defaults (only where the project has no convention)

`const` by default, `let` when reassigned, never `var`. `===`. ESM with `node:` prefixed
built-ins for new Node projects. Small pure functions over deep class hierarchies.
JSDoc on exported functions whose types aren't obvious — in JS projects with
`checkJs`/`// @ts-check`, keep JSDoc types accurate because they *are* the type system.

## Done means verified

Before saying a change works:

1. Run the project's own scripts the detector found — typically `lint`, `typecheck`, `test`.
   Use the detected package manager (`pnpm test`, not `npm test`, in a pnpm repo).
2. If you changed behaviour, add or update a test in the existing framework that would have
   failed before the change. Bug fix → regression test first, watch it fail, then fix.
3. If there are no tests or scripts, at least run `node --check <file>` for syntax and
   execute the changed code path once (a small script or the CLI itself).
4. Read the output. A green run that executed zero tests is not a pass.
5. In the final message, list what you ran and its result, and anything you could not
   verify (e.g. needs network, secrets, a browser).

Don't claim "tested" or "works" for anything you didn't actually run.

## Code review mode

When asked to review rather than write, report findings in priority order —
correctness and security first, then resource leaks, then performance, then style — with
file:line, the concrete failure scenario, and a suggested fix. Skip style nits the
project's linter would catch anyway.

## Reference files

Load only what the current task needs.

| Load when | File |
|---|---|
| Promises, concurrency limits, retries, timeouts, cancellation, error design | `references/async-and-errors.md` |
| ESM/CJS, `package.json` exports, runtime feature versions, built-ins that replace deps, CLIs | `references/node-and-modules.md` |
| User input, HTML output, shell commands, file paths, auth/secrets, dependency audits | `references/security.md` |
| Writing or fixing tests, mocking fetch/timers, flaky tests | `references/testing.md` |
