# Async patterns and error handling

## Contents
- Sequential vs parallel vs bounded
- Timeouts and cancellation
- Retries
- Error design
- Process-level handling (Node)

## Sequential vs parallel vs bounded

```js
// Sequential: each step needs the previous result, or order matters.
for (const id of ids) await save(id);

// Parallel: independent, and the count is small and known.
const [user, orders] = await Promise.all([getUser(id), getOrders(id)]);

// Partial failure is acceptable: inspect each outcome.
const results = await Promise.allSettled(tasks);
const failed = results.filter((r) => r.status === 'rejected');

// Bounded: many independent items (files, URLs, rows).
async function mapWithConcurrency(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  async function worker() {
    while (next < items.length) {
      const i = next++;               // safe: JS is single-threaded between awaits
      results[i] = await fn(items[i], i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}
```

If the first `fn` rejects, `mapWithConcurrency` rejects but other in-flight workers keep
running until their current item finishes. Pass an `AbortSignal` into `fn` if they must stop.
If the project already depends on `p-limit`/`p-map`, use that instead.

`await` inside a loop is correct when work is truly sequential; ESLint's `no-await-in-loop`
is a hint, not a law.

## Timeouts and cancellation

Prefer signals over `Promise.race`: a signal cancels the actual work (socket closed, listener
removed), whereas racing only stops *waiting* for it.

```js
// Timeout only
const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });

// Caller cancellation + timeout (AbortSignal.any: Node 20.3+, modern browsers)
const signal = AbortSignal.any([callerSignal, AbortSignal.timeout(10_000)]);

try {
  const res = await fetch(url, { signal });
  if (!res.ok) throw new HttpError(res.status, `GET ${url} -> ${res.status}`);
  return await res.json();
} catch (err) {
  if (err?.name === 'TimeoutError') { /* AbortSignal.timeout fired */ }
  if (err?.name === 'AbortError') { /* aborted by controller.abort() */ }
  throw err;
}
```

Accept an optional `{ signal }` in your own long-running async functions and pass it down.
Check `signal.throwIfAborted()` between expensive steps.

If you must use `setTimeout` for a timeout, clear it in `finally`, otherwise it keeps the
Node process alive and fires later.

## Retries

Retry only idempotent operations and only retryable failures (network errors, 408, 429,
5xx) — never 4xx validation errors. Back off exponentially with jitter and respect cancellation.

```js
import { setTimeout as sleep } from 'node:timers/promises';

async function withRetry(fn, { attempts = 3, baseMs = 200, signal, isRetryable = () => true } = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn({ signal });
    } catch (err) {
      if (attempt >= attempts || signal?.aborted || !isRetryable(err)) throw err;
      const delay = baseMs * 2 ** (attempt - 1) * (0.5 + Math.random()); // jitter
      await sleep(delay, undefined, { signal });
    }
  }
}
```

Honour a `Retry-After` header on 429/503 when present. In the browser, replace
`node:timers/promises` with a small signal-aware `setTimeout` wrapper.

## Error design

- Subclass `Error` only when callers need to branch on the type; set `name` and keep extra
  fields data-only:

  ```js
  class HttpError extends Error {
    constructor(status, message, options) {
      super(message, options);   // options carries { cause }
      this.name = 'HttpError';
      this.status = status;
    }
  }
  ```
- Branch with `instanceof` for your own classes; for errors crossing package or realm
  boundaries (workers, iframes, duplicated deps) check `err.name` / `err.code` instead.
- Error messages say what was being attempted and with what input (minus secrets):
  `Reading config at ${path} failed`, not `Error occurred`.
- Expected outcomes (not found, invalid input) can be return values; unexpected ones throw.
  Follow whichever style the codebase already uses.
- `AggregateError` (from `Promise.any`) holds its children in `.errors`.

## Process-level handling (Node)

- Since Node 15 an unhandled rejection terminates the process. Fix the floating promise
  rather than adding a global handler that hides it.
- A top-level `process.on('unhandledRejection'|'uncaughtException')` is for logging and a
  clean exit, not for continuing as if nothing happened.
- In servers, handle `SIGTERM`/`SIGINT`: stop accepting connections, finish in-flight work
  with a deadline, close DB pools, then exit.
- Use `queueMicrotask` / `setImmediate` to split CPU-heavy loops only as a stopgap; real
  CPU work belongs in `worker_threads` (or a Web Worker in the browser).
