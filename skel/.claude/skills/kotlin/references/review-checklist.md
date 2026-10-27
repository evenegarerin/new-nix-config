# Kotlin review checklist

Use for reviewing someone's Kotlin and for self-review before finishing. Report
findings ordered by severity, each with file/line, why it matters, and a concrete
fix. Don't pad a review with style nits a configured linter would catch anyway;
mention them once as "run ktlint/detekt".

## Severity 1 — bugs and hazards

- [ ] `runCatching { }` or `catch (e: Exception/Throwable)` around suspend calls
      without rethrowing `CancellationException`
- [ ] `GlobalScope`, inline `CoroutineScope(...)`, or `launch` from a suspend
      function with no owner
- [ ] Blocking call (JDBC, `File.readText`, `Thread.sleep`, blocking HTTP) on a
      coroutine without `withContext(io)`; `runBlocking` inside a coroutine or on
      the Android main thread
- [ ] `withContext` inside `flow { }` (runtime crash) — should be `flowOn`
- [ ] `MutableStateFlow`/`MutableList` exposed publicly; read-modify-write via
      `value = value.copy(...)` from concurrent callers (use `update {}`)
- [ ] `synchronized`/locks held across suspension, or non-reentrant `Mutex` re-entered
- [ ] `!!` on values that can legitimately be null (Java returns, map lookups,
      `findViewById`, deserialized fields)
- [ ] Platform types (`T!`) flowing into Kotlin code without an explicit type
- [ ] `data class` JPA entity; `equals`/`hashCode` over mutable fields used in sets/maps
- [ ] `when` over a sealed type with `else ->` that hides future subtypes
- [ ] `lateinit` read before guaranteed initialization
- [ ] `stateIn`/`shareIn` inside a function called repeatedly
- [ ] `callbackFlow` without `awaitClose`; `suspendCoroutine` where cancellation
      must reach the underlying call
- [ ] Code uses a language feature newer than the project's Kotlin version

## Severity 2 — design and maintainability

- [ ] New dependency or test framework introduced where the project already has one
- [ ] Error-handling style differs from the rest of the module
- [ ] Public API leaking implementation types; missing `internal`; library module
      without explicit API mode
- [ ] Binary-incompatible change to a published API without deprecation path
- [ ] Hard-coded dispatchers in classes that need tests
- [ ] Domain primitives as raw `String`/`Long` where mix-ups are plausible
      (consider value classes)
- [ ] `kotlin.Result` used as a domain error type across layers
- [ ] Extension functions with domain meaning on `String`/`Any` in shared scope
- [ ] Nested scope functions (`?.let { ... ?.let { } }`), unnamed `it` in long lambdas
- [ ] Test uses `Thread.sleep`/`runBlocking`, real dispatchers, or mocks where a fake would do

## Severity 3 — idiom polish (only if no linter covers it)

- [ ] `var` that is never reassigned; mutable collection that is never mutated
- [ ] Block body that is a single expression; `if`/`when` statement that could be
      an expression
- [ ] `values()` instead of `entries` (1.9+); `object` instead of `data object` for
      sealed singletons (1.9+)
- [ ] Manual null checks instead of `?.`/`?:`; `if (x != null) x else y` → `x ?: y`
- [ ] Missing named arguments for boolean/same-typed parameters
- [ ] `Sequence` on tiny collections, or long eager chains on huge ones
- [ ] Missing KDoc on public API

## Verification

- [ ] Compiled with the project's wrapper
- [ ] Touched tests (and new ones) run and pass
- [ ] `check` (lint/detekt/apiCheck if configured) passes or findings are explained
