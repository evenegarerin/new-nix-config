---
name: kotlin-best-practices
description: >
  Write, review, refactor and debug Kotlin code so it is idiomatic, matches the
  project it lives in, uses only language features the project's Kotlin version
  supports, and is verified with the project's own build before being called done.
  Covers null safety, immutability, sealed hierarchies, coroutines and Flow
  (cancellation, dispatchers, StateFlow), error handling, Java interop, library
  API design and testing. Use this skill whenever a task touches .kt or .kts files,
  build.gradle.kts, Kotlin coroutines or Flow, Ktor, Spring with Kotlin, Android
  or KMP Kotlin code, or Kotlin tests (JUnit, Kotest, MockK, Turbine) — including
  bug fixes, code review, "make this more idiomatic" and Java-to-Kotlin questions,
  even if the user never says "best practices".
license: Apache-2.0
metadata:
  version: "1.0.0"
  kotlin-checked-against: "2.4"
---

# Kotlin best practices

Most Kotlin advice is well known (prefer `val`, avoid `!!`, no `GlobalScope`). The
mistakes that actually reach code review are subtler: using a feature the project's
compiler doesn't have, swallowing cancellation through `runCatching`, adding Kotest
to a JUnit project, or calling a task done without compiling it. This skill is
ordered around avoiding those.

## How to work

1. **Read the project before writing code** (section 1). Its conventions beat this file.
2. **Write the code** following sections 2–5, loading a reference file only when the
   task is in its area.
3. **Verify with the project's own build** (section 6). Not compiled = not done.
4. **Self-review** against `references/review-checklist.md` for non-trivial changes
   and for every code-review request.

Reference files (load on demand, not up front):

| File | Load when |
|---|---|
| `references/coroutines-and-flow.md` | Any `suspend`, `launch`, `async`, `Flow`, `StateFlow`, `Channel`, dispatcher or scope work; cancellation or concurrency bugs |
| `references/interop-and-library-apis.md` | Kotlin called from Java (or vice versa), public library APIs, binary compatibility, serialization of public types |
| `references/testing.md` | Writing or fixing tests, especially coroutine/Flow tests |
| `references/review-checklist.md` | Reviewing Kotlin code (yours or the user's) |

## 1. Read the project first

Run `scripts/detect_kotlin_project.sh [project-root]` if a shell is available — it
prints the Kotlin version, build system, platform plugins, test libraries, linters
and explicit-API mode in one pass. Otherwise check these by hand:

- **Kotlin version**: `gradle/libs.versions.toml`, `kotlin("jvm") version ...`,
  `org.jetbrains.kotlin.*` plugin, or `<kotlin.version>` in `pom.xml`.
- **Platform**: JVM server, Android (`com.android.*`), Multiplatform
  (`kotlin("multiplatform")`), Spring (`plugin.spring`), JPA (`plugin.jpa`).
- **Test stack**: JUnit 4 vs 5, `kotlin("test")`, Kotest, MockK vs Mockito,
  Turbine, `kotlinx-coroutines-test`.
- **Style gates**: `.editorconfig`, detekt, ktlint, Spotless; `explicitApi()`.
- **Neighbouring code**: open two or three files near where you will write. Copy
  their error-handling style (exceptions vs `Result` vs sealed results), DI style,
  naming and package layout.

Rules that follow from this:

- **Project conventions override this skill.** If the codebase returns `Result<T>`
  everywhere, don't introduce a sealed `Either`; if it uses Mockito, don't add MockK.
- **Don't add dependencies to solve small problems.** Adding Arrow, Kotest, MockK,
  Turbine or kotlinx-datetime is a decision for the user; mention it, don't do it.
- **Version catalogs**: if `libs.versions.toml` exists, add versions there and
  reference aliases, never hard-coded coordinates in a module build file.

## 2. Version gating — only use what the compiler supports

Features below are safe only at or above the listed version. Below it, use the
fallback. "Preview" features need a compiler flag; don't enable flags unprompted.

| Feature | Stable since | Fallback |
|---|---|---|
| `data object`, `enum.entries` (instead of `values()`), `..<` | 1.9 | `object` with `toString`, `values()`, `until` |
| K2 compiler default, smarter smart-casts | 2.0 | explicit casts / local `val` copies |
| Guard conditions `is X if cond ->` in `when`; non-local `break`/`continue` in inline lambdas; `$$"..."` multi-dollar strings | 2.2 | nested `if`, labels, `${'$'}` |
| `kotlin.time.Clock` / `kotlin.time.Instant` in stdlib | 2.3 | `java.time` (JVM) or kotlinx-datetime if already a dependency |
| Context parameters `context(log: Logger) fun ...` | 2.4 (preview 2.2–2.3) | explicit parameter or receiver |
| Explicit backing fields (`val x: StateFlow<T>` with `field = MutableStateFlow(...)` on the next line) | 2.4 | `private val _x` + `val x = _x.asStateFlow()` |
| `kotlin.uuid.Uuid` (non-generation API) | 2.4 | `java.util.UUID` |

Context *receivers* (`context(Logger)` without a name) are the old, replaced
experiment — never write new code with them. If you cannot determine the version,
write code that compiles on 2.0 and say so.

## 3. Language idioms that matter

These are the defaults. Each has a reason; when the reason doesn't apply, neither
does the rule.

**Nullability is part of the type, so use it.**
- Non-null by default. A nullable return means "absence is a normal outcome".
- `!!` asserts "a bug if null" without saying why. Prefer `requireNotNull(x) { "why" }`
  for arguments, `checkNotNull(x) { "why" }` for state, or `?: error("why")`.
- Values coming from Java without nullability annotations are *platform types*
  (`String!`). Give them an explicit Kotlin type at the boundary so null-safety
  starts there instead of failing deep inside your code.
- `lateinit` only for framework-injected or lifecycle-initialised fields; never for
  values you could pass to the constructor. Use `by lazy` for expensive derived values.

**Make illegal states unrepresentable.**
- `sealed interface` (or `sealed class` when subtypes share state) for closed
  hierarchies; consume with an exhaustive `when` **without `else`**, so adding a
  subtype is a compile error at every call site instead of a silent fallthrough.
- `@JvmInline value class UserId(val value: String)` for IDs and units that are
  easy to mix up. Validate in `init` with `require`.
- `data class` for values. Not for JPA/Hibernate entities (all-field `equals`/
  `hashCode` breaks with proxies and dirty tracking — use a regular class with
  ID-based equality), and not when `copy()` would let callers bypass validation.
  A `data class` with a private constructor still exposes a public `copy()` unless
  `@ConsistentCopyVisibility` is applied (2.0.20+).

**Prefer immutability at API boundaries.**
- `val` over `var`; expose `List`/`Map`/`Set`, keep `MutableList` private. Note
  read-only ≠ immutable: a `List` you return can still be a mutable list someone
  casts. Return copies (`toList()`) from classes that keep mutable state.
- Mutable state in a class: one private mutable holder, one read-only view.

**Keep it readable, not clever.**
- Expression bodies for single expressions; block bodies once there is branching
  logic worth naming.
- Scope functions: `apply` to configure, `also` for side effects, `let` for
  nullable chains or narrowing, `run`/`with` sparingly. Never nest them more than
  one level, and name `it` when the lambda is longer than a line.
- Extension functions for behaviour that reads naturally on the type; keep
  them `private` or `internal` unless they are deliberately public API. Don't
  write extensions on `Any`, `String` or `Int` with domain meaning
  (`String.toUserId()` in a shared package pollutes every string).
- Named arguments for booleans and same-typed parameters: `copy(force = true)`.
- `require` (bad argument → `IllegalArgumentException`), `check` (bad state →
  `IllegalStateException`), `error("...")` (unreachable).
- Use `Sequence` only for long chains over large or infinite inputs; for small
  collections, plain `List` operations are faster and clearer.
- `const val` for compile-time constants; `SCREAMING_CASE` only for those and
  for deeply immutable top-level/object values.

## 4. Error handling

Pick one model per layer and follow the project's existing one:

- **Exceptions** for programming errors and truly exceptional failures.
- **Nullable return** when "not found" is the only failure.
- **Sealed result type** when callers must handle several domain outcomes
  differently (validation error vs conflict vs not found).
- **`kotlin.Result`** for wrapping a single throwing call at a boundary — it
  carries an untyped `Throwable`, so don't use it as the domain error model.

Two traps:

- `runCatching { }` catches **every** `Throwable`, including
  `CancellationException` (breaks coroutine cancellation) and `Error`s like
  `OutOfMemoryError`. Never use it around suspend calls without rethrowing
  cancellation — see `references/coroutines-and-flow.md` for a safe helper.
- `catch (e: Exception)` in suspend code also catches `CancellationException`.
  Rethrow it first, or catch the specific exception types you can handle.

## 5. Coroutines — the non-negotiables

Load `references/coroutines-and-flow.md` for anything beyond these.

- Every coroutine has an owner: `coroutineScope {}` inside suspend functions,
  `viewModelScope`/`lifecycleScope` on Android, an injected application scope
  for app-lifetime work. Never `GlobalScope`; never `CoroutineScope(...)` created
  inline and forgotten.
- Suspend functions are **main-safe**: the function that does blocking IO wraps it
  in `withContext(ioDispatcher)`; callers don't.
- Inject dispatchers (constructor parameter with a default) so tests can replace them.
- `runBlocking` only in `main`, tests of non-suspend code, and bridges from
  blocking APIs — never inside a coroutine or on Android's main thread.
- Cooperative cancellation in CPU loops: `yield()` or
  `currentCoroutineContext().ensureActive()`. A bare `ensureActive()` only compiles
  inside a `CoroutineScope` receiver (e.g. within `coroutineScope { }`) — several
  published Kotlin skills get this wrong.
- Never change context inside `flow { }` with `withContext`; use `.flowOn(...)`.
- Expose `StateFlow`/`Flow`, keep `MutableStateFlow` private; update with
  `update { }` rather than `value = value.copy(...)` to avoid lost updates.

## 6. Verify before calling it done

Use the project's wrapper and its real task names; don't install global tools.

```bash
./gradlew :module:compileKotlin            # or compileDebugKotlin / compileKotlinJvm for Android / KMP
./gradlew :module:test --tests 'com.example.FooTest'   # the tests you touched first
./gradlew :module:check                     # includes detekt/ktlint/apiCheck if the project configured them
```

(Maven: `./mvnw -q -pl module compile` / `test`.) Run the narrowest task that proves
the change, then widen. If a linter is configured, fix its findings rather than
adding suppressions; if a suppression is unavoidable, scope it to the line and say why.

If you cannot run the build (no shell, no JDK, network-restricted dependencies),
say so explicitly in the reply and list what the user should run. Never claim
code compiles or tests pass without having run them.

When finishing, report briefly: what changed, what was verified and how, and any
decision deferred to the user (new dependency, compiler flag, behaviour change).
