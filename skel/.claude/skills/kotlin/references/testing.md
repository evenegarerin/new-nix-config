# Testing Kotlin

Contents: 1. Match the existing stack · 2. Test design · 3. Coroutine tests ·
4. Flow tests · 5. Running tests

## 1. Match the existing stack

Look at an existing test in the same module and copy its framework, assertion
library, mocking library, naming and directory layout. If the module has no tests,
use the stack of the nearest module that does. Only if the whole project has none,
default to `kotlin("test")` with JUnit 5 and plain fakes, and tell the user.

| If you see | Write |
|---|---|
| `org.junit.jupiter` | JUnit 5 `@Test`, backtick names `` `returns empty list when no users` `` |
| `org.junit.Test` (JUnit 4) | JUnit 4 — don't migrate the module as a side effect |
| `io.kotest` | the same spec style (`FunSpec`, `StringSpec`, ...) as neighbouring tests |
| `io.mockk` | MockK (`coEvery`/`coVerify` for suspend functions) |
| `org.mockito.kotlin` | mockito-kotlin (`whenever`, `any()`) |
| `app.cash.turbine` | Turbine for Flow assertions |

## 2. Test design

- **Prefer fakes over mocks** for your own interfaces: a small in-memory
  implementation is easier to read and doesn't break when call order changes.
  Mock third-party boundaries you can't fake cheaply.
- Test behaviour through the public API; don't make things `public` for tests —
  `internal` is visible to the same module's tests.
- One reason to fail per test; name says the scenario and expected result.
- Use `data class` equality in assertions instead of field-by-field checks.
- For parsing/serialization/validation logic, consider property-based tests if
  the project already has a library for them (Kotest property, jqwik).

## 3. Coroutine tests

Use `runTest` from `kotlinx-coroutines-test`. It runs on a virtual clock:
`delay(10.minutes)` completes instantly.

```kotlin
@Test
fun `refresh publishes loaded state`() = runTest {
    val repo = FakeRepository(items = listOf(item))
    val model = ItemsModel(repo, dispatcher = StandardTestDispatcher(testScheduler))

    model.refresh()
    advanceUntilIdle()

    assertEquals(ItemsState.Loaded(listOf(item)), model.state.value)
}
```

Rules:
- Pass test dispatchers that share `testScheduler` into the code under test
  (that's why dispatchers are injected). A hard-coded `Dispatchers.IO` escapes
  the virtual clock and makes tests slow or flaky.
- `StandardTestDispatcher` queues work until you advance (`advanceUntilIdle`,
  `advanceTimeBy`, `runCurrent`) — good for asserting intermediate states.
  `UnconfinedTestDispatcher` runs eagerly — good for collectors that should see
  every emission.
- Android code using `Dispatchers.Main`: `Dispatchers.setMain(testDispatcher)` in
  setup and `Dispatchers.resetMain()` in teardown (usually via a JUnit rule/extension
  the project already has).
- Never-ending collectors in tests: launch them in `backgroundScope`, which is
  cancelled automatically at the end of `runTest`. Launching them in the test
  scope makes `runTest` hang or fail with "unfinished coroutines".
- Don't use `runBlocking` or `Thread.sleep` in coroutine tests.

## 4. Flow tests

With Turbine (if present):

```kotlin
@Test
fun `search emits results for latest query`() = runTest {
    model.results.test {
        model.query("ko")
        assertEquals(emptyList(), awaitItem())
        assertEquals(listOf(kotlinResult), awaitItem())
        cancelAndIgnoreRemainingEvents()
    }
}
```

Without Turbine:

```kotlin
@Test
fun `state reflects updates`() = runTest {
    val seen = mutableListOf<State>()
    backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
        model.state.toList(seen)
    }
    model.update(42)
    assertEquals(listOf(State.Initial, State.Value(42)), seen)
}
```

For finite flows, `flow.toList()` or `flow.first()` is enough.

Remember `StateFlow` conflation: with a `StandardTestDispatcher`, rapid updates
may be observed only as the final value. Assert on what users can observe, not
on every intermediate write.

## 5. Running tests

Run the narrowest set first, then the module:

```bash
./gradlew :module:test --tests 'com.example.ItemsModelTest'
./gradlew :module:test
# Android unit tests: ./gradlew :app:testDebugUnitTest
# KMP: ./gradlew :shared:allTests  (or :shared:jvmTest for the fast loop)
```

A test you wrote and never ran is a guess. If you can't run it, say so.
