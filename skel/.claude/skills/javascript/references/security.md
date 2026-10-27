# Security for JavaScript and Node.js

Apply these whenever code touches data that came from outside the process: HTTP requests,
files, env vars, CLI args, URL params, `postMessage`, third-party APIs, LLM output.

## Contents
- Injection: HTML, shell, SQL, code
- Paths and files
- Objects from untrusted input
- Regular expressions
- Secrets, auth and crypto
- Outbound requests
- Dependencies

## Injection

**HTML (XSS).** Set text with `textContent`, attributes with `setAttribute` on a known-safe
attribute name. `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`,
React's `dangerouslySetInnerHTML` and Vue's `v-html` need sanitized input (DOMPurify or the
project's sanitizer). URLs placed in `href`/`src` must be checked for an allowed scheme
(`https:`, `mailto:`), since `javascript:` URLs execute.

**Shell.** Never build a command string from input.

```js
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);

// Arguments are passed as an array: no shell, no word splitting, no injection.
const { stdout } = await execFileAsync('git', ['log', '--format=%H', '--', userPath]);
```

The `--` stops a value starting with `-` from being read as an option. Avoid `shell: true`.

**SQL / NoSQL.** Parameterized queries or the ORM's query builder only; never template
literals into SQL. For MongoDB-style queries, reject objects where a string is expected
(`{ "$ne": null }` in a password field bypasses login).

**Code.** No `eval`, `new Function`, `vm` (it is not a sandbox), or `setTimeout` with a string.

## Paths and files

```js
import path from 'node:path';

function safeJoin(baseDir, userPath) {
  const base = path.resolve(baseDir);
  const target = path.resolve(base, userPath);
  if (target !== base && !target.startsWith(base + path.sep)) {
    throw new Error('Path escapes base directory');
  }
  return target;
}
```

Also consider symlinks inside the base (`fs.realpath` the target if attackers can create
files), and set size limits on uploads and request bodies.

## Objects from untrusted input

- Merging parsed JSON into existing objects with recursive merge/`set(path, value)` helpers
  allows `__proto__` / `constructor.prototype` pollution. Validate shape first (the project's
  schema library: zod, valibot, ajv, joi…) and copy only known fields.
- Use `Map` or `Object.create(null)` for dictionaries keyed by user input.
- Use `Object.hasOwn(obj, key)` rather than `key in obj` or `obj[key]` truthiness when the
  key is user-supplied.

## Regular expressions

Nested quantifiers like `(a+)+`, `(.*)*` or overlapping alternations can take exponential
time on crafted input (ReDoS) and block the event loop. Keep patterns linear, anchor them,
cap input length before matching, and prefer `URL`, `JSON.parse` or a real parser over
regex for structured formats.

## Secrets, auth and crypto

- Read secrets from env/secret manager; never hard-code or commit them; never log tokens,
  passwords, cookies, or full request headers.
- Random tokens: `crypto.randomBytes(32).toString('base64url')` or `crypto.randomUUID()`.
  Never `Math.random()` for anything security-relevant.
- Compare secrets with `crypto.timingSafeEqual` on equal-length buffers.
- Passwords: `crypto.scrypt` or the project's bcrypt/argon2 — never a plain hash.
- Cookies carrying sessions: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`.
- Don't hand-roll JWT verification; use the project's library and pin the allowed algorithm.

## Outbound requests

When fetching a URL that a user supplied (webhooks, previews, imports), restrict scheme
and host, and block private/link-local addresses to prevent SSRF against internal services
and cloud metadata endpoints. Always set a timeout.

## Dependencies

- Don't add dependencies for trivial helpers; each one is supply-chain surface.
- Check a package's name carefully (typosquats) and prefer well-maintained ones.
- Run the package manager's audit (`npm audit`, `pnpm audit`, `yarn npm audit`) when asked
  to review dependencies; report findings rather than running `audit fix --force`,
  which can apply breaking upgrades.
- Commit the lockfile; in CI use the frozen-install command (`npm ci`,
  `pnpm install --frozen-lockfile`, `yarn install --immutable`).
