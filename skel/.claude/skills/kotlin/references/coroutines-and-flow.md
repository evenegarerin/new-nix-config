# Coroutines and Flow

Contents: 1. Scopes and ownership · 2. Dispatchers · 3. Cancellation · 4. Exceptions ·
5. Shared mutable state · 6. Flow · 7. StateFlow / SharedFlow · 8. Bridging callbacks ·
9. Platform notes

## 1. Scopes and ownership

Structured concurrency means every coroutine has a parent that waits for it and
cancels it. Pick the scope by *who owns the lifetime*:

| Situation | Use |
|---|---|
| Parallel work inside a suspend function, all must succeed | `coroutineScope { async {...}; async {...} }` |
| Parallel work where one child failing must not cancel the others | `supervisorScope { }` and handle each child's failure |
| Android ViewModel / UI | `viewModelScope`, `lifecycleScope` + `repeatOnLifecycle` |
| Work that must outlive the caller (e.g. finish a write after the screen closes) | An injected application-level `CoroutineScope` with `SupervisorJob()`, cancelled on shutdown |
| Server request handling (Ktor, Spring WebFlux) | The framework's request scope; don't launch detached jobs |

```kotlin
suspend fun loadProfile(id: UserId): Profile = coroutineScope {
    val user = async { users.get(id) }
    val posts = async { posts.forUser(id) }
    Profile(user.await(), posts.await())
}
```

`async` inside `coroutineScope` propagates failure to the scope even if nobody
calls `await()` — siblings are cancelled and the exception rethrown. That is
usually what you want.

Avoid:
- `GlobalScope.launch` — no owner, leaks, untestable.
- `CoroutineScope(Dispatchers.IO).launch { }` inline — same problem with extra steps.
- `launch` from a suspend function to "fire and forget" — the function returns
  before the work finishes and errors go nowhere. Either `await` it or take an
  explicit scope parameter so the caller sees the lifetime decision.

## 2. Dispatchers

- `Dispatchers.Default`: CPU work. `Dispatchers.IO`: blocking IO (JDBC, files,
  blocking HTTP clients). `Dispatchers.Main`: UI only.
- Suspending libraries (Ktor client, Retrofit suspend functions, Room suspend
  DAOs, R2DBC) are already main-safe — wrapping them in `withContext(IO)` is noise.
- Inject the dispatcher; default it for production:

```kotlin
class ReportRepository(
    private val db: Database,
    private val io: CoroutineDispatcher = Dispatchers.IO,
) {
    suspend fun load(id: ReportId): Report = withContext(io) { db.blockingQuery(id) }
}
```

- To cap parallelism against a limited resource use
  `Dispatchers.IO.limitedParallelism(n)` instead of creating thread pools.
- `newSingleThreadContext`/`Executors...asCoroutineDispatcher()` must be closed;
  prefer `limitedParallelism(1)` for confinement.

## 3. Cancellation

Cancellation is cooperative: it is delivered at suspension points
(`delay`, `withContext`, `yield`, most suspending IO). Long CPU loops need checks:

```kotlin
suspend fun crunch(items: List<Item>): Int {
    var total = 0
    for (item in items) {
        currentCoroutineContext().ensureActive()   // or yield() to also let others run
        total += expensive(item)
    }
    return total
}
```

`ensureActive()` without a receiver compiles only inside a `CoroutineScope`
lambda (`coroutineScope { }`, `launch { }`, `withContext { }`). In a plain
suspend function body use `currentCoroutineContext().ensureActive()` or `yield()`.

Cleanup that must suspend after cancellation needs `NonCancellable`:

```kotlin
try {
    upload(file)
} finally {
    withContext(NonCancellable) { tempStore.delete(file.id) }
}
```

Blocking calls (`Thread.sleep`, JDBC) ignore cancellation; use `runInterruptible`
around interruptible blocking calls when timely cancellation matters.

## 4. Exceptions

**Never swallow `CancellationException`.** Generic catches catch it:

```kotlin
// WRONG: cancellation becomes a "failed" result and the coroutine keeps running
val r = runCatching { api.fetch() }

// WRONG for the same reason
try { api.fetch() } catch (e: Exception) { log(e) }

// RIGHT
try {
    api.fetch()
} catch (e: CancellationException) {
    throw e
} catch (e: IOException) {
    log(e); fallback()
}
```

If the project wants a `runCatching`-style helper for suspend code, add one
explicitly rather than using the stdlib one:

```kotlin
inline fun <T> runSuspendCatching(block: () -> T): Result<T> =
    try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Result.failure(e)
    }
```

(It is `inline` so it can wrap suspend calls without being `suspend` itself, and
it deliberately doesn't catch `Error`.)

Other rules:
- `CoroutineExceptionHandler` only works on root coroutines (`launch` directly in
  a scope). It does nothing for `async` or nested children.
- `supervisorScope`: a failing `async` child throws at `await()`; a failing
  `launch` child goes to the handler. Handle both explicitly.
- `withTimeout` throws `TimeoutCancellationException` (a `CancellationException`)
  — it will be swallowed by the patterns above if you aren't careful. Prefer
  `withTimeoutOrNull` when timeout is an expected outcome.

## 5. Shared mutable state

- Prefer confinement (one coroutine owns the state) or immutable snapshots in a
  `MutableStateFlow` updated with `update { it.copy(...) }` (atomic CAS loop).
- `Mutex` when the critical section suspends; `synchronized`/`ReentrantLock` can't
  span suspension points (and `synchronized` around a suspend call doesn't compile).
- `Mutex` is not reentrant — calling a locked function from inside the lock deadlocks.
- `AtomicInteger`/`AtomicReference` (JVM) or `kotlin.concurrent.atomics` for counters.
- For tricky lock-free code on the JVM, Lincheck can test linearizability.

## 6. Flow

- Cold `flow { }` runs per collector. Context preservation: never `withContext`
  inside `flow { }` — it throws `IllegalStateException` at runtime. Use `flowOn`:

```kotlin
fun lines(path: Path): Flow<String> = flow {
    Files.newBufferedReader(path).use { r -> r.lineSequence().forEach { emit(it) } }
}.flowOn(Dispatchers.IO)
```

- `catch { }` only catches upstream errors; put it after the operators it guards.
  Rethrowing is the default for anything you don't handle.
- Operators by intent: `map`/`filter`; `mapLatest`/`flatMapLatest` (cancel stale
  work, e.g. search-as-you-type); `debounce`; `distinctUntilChanged`; `combine`
  (latest of each); `zip` (pairwise); `conflate`/`buffer` (backpressure);
  `retryWhen` with a bounded attempt count.
- Terminal operators suspend: `collect`, `first`, `toList`, `single`. `launchIn(scope)`
  is `scope.launch { collect() }` — the scope still owns it.
- Don't expose `Channel` in APIs; expose `Flow` (use `receiveAsFlow()`).

## 7. StateFlow / SharedFlow

Expose read-only state. On Kotlin 2.4+ use an explicit backing field:

```kotlin
class CounterModel {
    val count: StateFlow<Int>
        field = MutableStateFlow(0)

    fun increment() = count.update { it + 1 }   // `field` type is visible inside the class
}
```

On earlier versions:

```kotlin
private val _count = MutableStateFlow(0)
val count: StateFlow<Int> = _count.asStateFlow()
```

Turning a cold flow into UI state:

```kotlin
val uiState: StateFlow<UiState> = repository.observe()
    .map(UiState::Content)
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)
```

`WhileSubscribed(5_000)` keeps the upstream alive across configuration changes
but stops it when nobody watches. Don't call `stateIn`/`shareIn` inside a function
that's called repeatedly — each call starts a new upstream.

`StateFlow` conflates and uses equality: emitting an equal value is a no-op, and
fast intermediate values can be skipped. For one-off events (navigation, toasts)
either model them as state the UI consumes and clears, or use a
`Channel(Channel.BUFFERED)` exposed via `receiveAsFlow()`; a `SharedFlow` with
no replay drops events emitted while nobody is collecting.

## 8. Bridging callbacks and blocking APIs

```kotlin
fun LocationClient.updates(): Flow<Location> = callbackFlow {
    val listener = Listener { trySend(it) }
    register(listener)
    awaitClose { unregister(listener) }       // mandatory: runs on cancellation
}

suspend fun Call.await(): Response = suspendCancellableCoroutine { cont ->
    enqueue(onSuccess = { cont.resume(it) }, onError = { cont.resumeWithException(it) })
    cont.invokeOnCancellation { cancel() }
}
```

Use `suspendCancellableCoroutine`, not `suspendCoroutine`, so cancellation
reaches the underlying call.

## 9. Platform notes

- **Android UI**: collect with `repeatOnLifecycle(Lifecycle.State.STARTED)` (Views)
  or `collectAsStateWithLifecycle()` (Compose). `launchWhenStarted` is deprecated.
- **Spring**: suspend controller methods and `Flow` returns are supported in
  WebFlux and recent MVC; don't wrap in `runBlocking`. `@Transactional` on suspend
  functions needs the reactive transaction manager.
- **Ktor**: handlers already run in a coroutine tied to the call; use
  `call.application` scope only for genuinely detached work.
- **KMP**: `Dispatchers.IO` isn't available in `commonMain` when JS or Wasm targets
  are present — check the targets, and inject dispatchers from platform code or a
  shared `expect` declaration.
