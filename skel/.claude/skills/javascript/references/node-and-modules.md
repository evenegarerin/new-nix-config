# Node.js, modules and runtime targets

## Contents
- ESM vs CommonJS
- package.json `exports`
- Feature → minimum Node version
- Built-ins that replace common dependencies
- Browser targets
- CLIs and scripts

## ESM vs CommonJS

Which one a `.js` file is depends on the nearest `package.json` `"type"`; `.mjs` is always
ESM and `.cjs` always CommonJS. Match the file's neighbours. Converting a codebase between
the two is a project decision, not a drive-by edit.

ESM specifics that commonly break:
- Relative imports need the file extension: `import { x } from './util.js'`.
- No `__dirname` / `__filename` / `require`. Use `import.meta.dirname` /
  `import.meta.filename` (Node 20.11+), or on older targets:
  ```js
  import { fileURLToPath } from 'node:url';
  const __dirname = fileURLToPath(new URL('.', import.meta.url));
  ```
  Don't use `new URL(...).pathname` — it is wrong on Windows and with spaces or
  non-ASCII characters in the path.
- JSON: `import data from './data.json' with { type: 'json' }` (Node 22+ syntax), or read
  and `JSON.parse` it, or `createRequire(import.meta.url)('./data.json')`.
- Top-level `await` works in ESM; it delays every importer of that module, so keep it out of
  library entry points.

Interop:
- ESM can `import` CommonJS (default import = `module.exports`; named imports work only
  when Node can detect them statically).
- CommonJS can load ESM via `await import()`. Node 22.12+ and 20.19+ also allow
  `require()` of ESM that has no top-level `await`. Check the target before relying on it.

## package.json `exports`

If `exports` is defined it is the package's public API: anything not listed cannot be
imported by consumers. When adding an entry point, add it there. Order conditions from most
specific to least, with `default` last:

```json
"exports": {
  ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js", "require": "./dist/index.cjs", "default": "./dist/index.js" },
  "./package.json": "./package.json"
}
```

Removing or renaming an `exports` path is a breaking change.

## Feature → minimum Node version

Check the detected target before using these. Browser support differs; check browserslist.

| Feature | Node |
|---|---|
| `Object.hasOwn`, `Error` `cause`, `Array.prototype.at` | 16.9 |
| `structuredClone`, `AbortSignal.timeout` | 17.3 |
| global `fetch`, `Array.prototype.findLast`, `node --watch` (18.11) | 18 |
| `util.parseArgs`, `node:test` (both stable in 20) | 18.3 |
| `toSorted` / `toReversed` / `toSpliced` / `with`, regex `v` flag | 20 |
| `AbortSignal.any` | 20.3 |
| `--env-file` | 20.6 |
| `import.meta.dirname` / `filename` | 20.11 |
| `process.loadEnvFile`, `util.styleText` | 20.12 |
| `Object.groupBy` / `Map.groupBy` | 21 |
| `Promise.withResolvers`, `Array.fromAsync`, Set methods (`union`, `intersection`…), iterator helpers, global `WebSocket` | 22 |
| `require()` of ESM without a flag | 22.12 / 20.19 |

When unsure whether the installed runtime supports something, test it:
`node -e "console.log(typeof Object.groupBy)"`.

## Built-ins that replace common dependencies

Reach for these before adding a package (respecting the version table):

| Instead of | Use |
|---|---|
| `node-fetch`, simple `axios` usage | `fetch` |
| `uuid` (v4) | `crypto.randomUUID()` |
| `lodash.clonedeep` | `structuredClone` (plain data; not functions or class instances) |
| `dotenv` | `node --env-file=.env` or `process.loadEnvFile()` |
| `minimist` / simple `yargs` | `util.parseArgs` |
| `rimraf`, `mkdirp` | `fs.rm(p, { recursive: true, force: true })`, `fs.mkdir(p, { recursive: true })` |
| `nodemon` (simple cases) | `node --watch` |
| `moment` for formatting | `Intl.DateTimeFormat`, `Intl.RelativeTimeFormat` |
| `lodash.groupby` | `Object.groupBy` (Node 21+) |

Don't rip out an existing dependency the project uses everywhere just because a built-in exists.

## Browser targets

- `browserslist` (in package.json or `.browserslistrc`) defines what must work. If a bundler
  with transpilation is present, syntax is usually handled, but **APIs are not** — a
  missing `Object.groupBy` will not be polyfilled unless the project already sets that up.
- Don't add polyfills or core-js imports unprompted; mention the gap instead.
- Code that runs in both Node and the browser must not import `node:` modules at the top
  level; use conditional `exports` or platform-specific entry files.

## CLIs and scripts

- Parse args with `util.parseArgs` (or the project's existing parser). Support `--help`.
- Results to stdout, diagnostics and errors to stderr, so output can be piped.
- Exit codes: 0 success, non-zero failure. Set `process.exitCode = 1` and let the event loop
  drain instead of calling `process.exit()` mid-write, which can truncate output.
- Add a `#!/usr/bin/env node` shebang and a `bin` entry in package.json for installable CLIs.
- Use `path.join` / `path.resolve` and `os.EOL` awareness for cross-platform paths; never
  concatenate paths with `/`.
