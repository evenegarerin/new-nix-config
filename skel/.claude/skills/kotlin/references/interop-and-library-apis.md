# Java interop and public library APIs

Contents: 1. Calling Java from Kotlin · 2. Calling Kotlin from Java ·
3. Designing public APIs · 4. Binary compatibility · 5. Framework-specific traps

## 1. Calling Java from Kotlin

- **Platform types**: unannotated Java returns are `T!`. Declare the Kotlin type
  where the value enters your code: `val name: String? = javaObj.name`. Pick
  non-null only if the Java side guarantees it (annotations, docs, or source).
- Java collections returned as `List<T>` may be mutable and shared; copy if you
  store them.
- SAM conversions: when a Java method is overloaded with different functional
  interfaces, a bare lambda is ambiguous — use `Runnable { }` / `Callable { }`.
- Java identifiers that are Kotlin keywords (`is`, `in`, `object`, `when`,
  `fun`) need backticks: ``mock.`when`(...)``.
- Kotlin has no checked exceptions; still catch the Java checked exceptions you
  can actually handle.

## 2. Calling Kotlin from Java

Only add these where Java callers exist — they're noise otherwise.

| Need | Annotation |
|---|---|
| Static method on a companion/object | `@JvmStatic` |
| Field instead of getter (constants, Android `CREATOR`) | `@JvmField` (or `const val` for primitives/strings) |
| Java overloads for default parameters | `@JvmOverloads` |
| Java callers must catch a checked exception | `@Throws(IOException::class)` |
| Nice class name for top-level functions | `@file:JvmName("Strings")` |
| Avoid signature clash after erasure | `@JvmName("filterInts")` |

Value classes are mangled in JVM signatures (`foo-abc123`), so functions taking
them aren't callable from Java; provide a Java-friendly overload or don't use
value classes in Java-facing APIs. `suspend` functions are awkward from Java —
offer a `CompletableFuture` wrapper (`scope.future { }` from
`kotlinx.coroutines.future`) if Java callers need them.

## 3. Designing public APIs (libraries, shared modules)

- Enable **explicit API mode** for library modules: `kotlin { explicitApi() }`.
  It forces explicit visibility and return types on public declarations so nothing
  becomes public by accident.
- Default to `internal`; `public` is a promise. `private` top-level declarations
  are file-private.
- Return interfaces/read-only types (`List`, `Flow`, `StateFlow`), accept the
  most general type you need.
- Don't expose `data class` in a stable public API unless you accept that
  adding a property changes the constructor, `copy`, and `componentN` — all
  binary-breaking. A regular class with a builder/factory evolves more safely.
- Prefer `sealed interface` for closed hierarchies; adding a subtype is
  source-breaking for exhaustive `when` in client code — document the policy.
- Put `@Deprecated(level = WARNING → ERROR → HIDDEN, replaceWith = ReplaceWith(...))`
  through a cycle instead of deleting.
- Opt-in annotations (`@RequiresOptIn`) mark experimental APIs instead of
  "please don't use" comments.
- KDoc every public declaration: what, not how; include `@throws` for documented
  exceptions and an example for non-obvious APIs.

## 4. Binary compatibility

- If the project publishes artifacts, check for ABI validation: the Kotlin Gradle
  plugin's built-in binary compatibility validation (newer KGP versions) or the
  older `org.jetbrains.kotlinx.binary-compatibility-validator` plugin (`apiCheck`,
  `apiDump`). Run the check after any public-API change; regenerate the dump only
  when the change is intended and say so.
- Adding a parameter with a default value is binary-breaking for compiled
  callers. Options: keep the old overload as `@Deprecated(level = HIDDEN)`, use
  `@JvmOverloads`, or (Kotlin 2.4+, experimental) `@IntroducedAt("x.y")`.
- Changing `inline` function bodies doesn't reach already-compiled callers on the
  JVM; treat public inline functions as frozen.

## 5. Framework-specific traps

- **Spring**: the `kotlin("plugin.spring")` (all-open) plugin is needed for
  proxies on `@Component`/`@Transactional` classes. Prefer constructor injection
  with `val` parameters; avoid `lateinit var` + field injection. Configuration
  properties work as constructor-bound `data class` or regular class.
- **JPA/Hibernate**: `kotlin("plugin.jpa")` (no-arg) is required. Entities are
  regular classes, not data classes; ID nullable (`var id: Long? = null`) with
  ID-based `equals` and a constant `hashCode`; `toString` must not touch lazy
  associations.
- **Jackson**: register `jackson-module-kotlin` so constructor defaults and
  nullability are respected; without it, missing fields become `null` in
  non-null properties.
- **kotlinx.serialization**: `@Serializable` classes are public API on the wire —
  renaming a property breaks the format; use `@SerialName` to decouple. Configure
  `Json { ignoreUnknownKeys = true }` for consuming external APIs.
- **Mockito**: final-by-default Kotlin classes need `mockito-inline` (default in
  Mockito 5) and `any()` returns null for non-null parameters — use
  mockito-kotlin helpers if the project already uses Mockito.
