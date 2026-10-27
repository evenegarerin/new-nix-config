# Testing JavaScript

## Contents
- Match the existing setup
- What a good test here looks like
- Mocking fetch, timers and modules
- Flaky tests
- When there is no test setup

## Match the existing setup

Open one or two existing test files (the detector lists some) and copy their framework,
file naming (`*.test.js` vs `__tests__/`), import style, assertion style, setup helpers and
fixture locations. Don't introduce a second runner or assertion library.

Run a single file while iterating, then the whole suite before finishing:

| Runner | One file | Filter by name |
|---|---|---|
| Vitest | `vitest run path/to/file.test.js` | `-t "name"` |
| Jest | `jest path/to/file.test.js` | `-t "name"` |
| node:test | `node --test path/to/file.test.js` | `--test-name-pattern="name"` |
| Mocha | `mocha path/to/file.test.js` | `--grep "name"` |

Invoke them through the package manager (`pnpm vitest run …`, `npx jest …`) so the
project's local version is used.

## What a good test here looks like

- Tests behaviour through the public interface, not private helpers or call counts of
  internal functions.
- One reason to fail per test; the name states the expected behaviour
  (`returns 0 for an empty cart`, not `test calculateTotal`).
- Covers the edges that matter in JS: empty arrays/strings, `0`, `null`/`undefined`,
  `NaN`, very large numbers, unicode/emoji strings, rejected promises, and timeouts.
- Async tests `await` the promise or return it. An un-awaited assertion passes vacuously.
  For expected rejections: `await expect(fn()).rejects.toThrow(...)` (Vitest/Jest) or
  `await assert.rejects(fn(), /message/)` (node:test).
- Bug fix → write the failing test first, see it fail for the right reason, then fix.

## Mocking fetch, timers and modules

Mock at the boundary (network, clock, filesystem, randomness), not the code under test.
Always restore mocks so tests don't leak into each other.

**node:test**

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';
import { getUser } from '../src/users.js';

test('getUser throws on 404', async (t) => {
  t.mock.method(globalThis, 'fetch', async () => new Response('nope', { status: 404 }));
  await assert.rejects(getUser(1), /404/);
}); // t.mock restores automatically after the test

test('retries after a delay', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });   // Node 20.4+
  // ... start the work, then:
  t.mock.timers.tick(1000);
});
```

**Vitest** (Jest is the same with `jest.` instead of `vi.`)

```js
import { afterEach, expect, test, vi } from 'vitest';

afterEach(() => { vi.restoreAllMocks(); vi.unstubAllGlobals(); vi.useRealTimers(); });

test('getUser throws on 404', async () => {
  vi.stubGlobal('fetch', vi.fn(async () => new Response('nope', { status: 404 })));
  await expect(getUser(1)).rejects.toThrow('404');
});

test('debounce fires once', () => {
  vi.useFakeTimers();
  const fn = vi.fn();
  const d = debounce(fn, 100);
  d(); d(); d();
  vi.advanceTimersByTime(100);
  expect(fn).toHaveBeenCalledTimes(1);
});
```

Module mocks (`vi.mock`, `jest.mock`) are hoisted above imports; reference only variables
created inside the factory or named `mock*`. Jest with native ESM needs
`--experimental-vm-modules` and `jest.unstable_mockModule`; check how the project runs it
before writing ESM module mocks.

Prefer dependency injection (pass `fetch`, a clock, or a repository as a parameter) when
writing new code: it makes most module mocking unnecessary.

## Flaky tests

Usual causes, in rough order: real network or real time (`Date.now()`, timers), shared
mutable state between tests (module-level caches, DB rows, env vars), test order
dependence, unawaited promises finishing after the test ends, and timezone/locale
differences (`TZ=UTC` in CI vs local). Fix the cause; don't add retries or bump timeouts.

## When there is no test setup

Don't scaffold a test framework unless asked. For a library or Node project, `node:test`
needs no install and is a reasonable thing to *suggest*. To verify your change in the
meantime, write a throwaway script that imports the changed function and asserts with
`node:assert/strict`, run it, and delete it (or offer to keep it as a test).
