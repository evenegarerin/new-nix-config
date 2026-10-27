# Testing Spring Boot applications

## Contents
1. Choosing the right test type
2. Unit tests (no Spring)
3. Slice tests
4. Integration tests with real infrastructure
5. Mocking beans and the context cache
6. Testing security
7. Testing HTTP clients, messaging, scheduling, time
8. Architecture tests
9. Test data and isolation
10. Common failures and what they mean

## 1. Choosing the right test type

| What you test | Test type | Spring context |
|---|---|---|
| Business logic in services, domain objects, mappers | Unit test | none |
| Controller mapping, validation, status codes, JSON, error format, security rules on endpoints | `@WebMvcTest` (MockMvc / MockMvcTester / RestTestClient) | web slice |
| Custom repository queries, mappings, constraints, migrations | `@DataJpaTest` (or `@JdbcTest`, `@DataJdbcTest`) + Testcontainers | JPA slice |
| JSON serialization of DTOs | `@JsonTest` | JSON slice |
| Outbound REST clients | `@RestClientTest` + `MockRestServiceServer`, or WireMock | client slice |
| A critical end-to-end flow, wiring, config, startup | `@SpringBootTest` + Testcontainers | full |

Default to the cheapest test that can catch the bug. A suite of mostly `@SpringBootTest`s is slow and brittle; a suite of only mocked unit tests misses wiring, SQL and serialization bugs. Aim for many unit tests, a solid layer of slice tests, a handful of full integration tests.

**Boot 4 note**: test slices are modularised along with the starters (e.g. MVC test support lives in its own test module/starter). If `@WebMvcTest` or `@DataJpaTest` can't be resolved after an upgrade, add the matching test starter rather than falling back to `@SpringBootTest`.

## 2. Unit tests (no Spring)

- Construct the class under test directly via its constructor, passing mocks or (better, where cheap) simple in-memory fakes. This is the payoff of constructor injection.
- Don't start a Spring context to test a service's `if` statements.
- Use an injected fixed `Clock` for time-dependent logic.
- Assert behaviour (returned values, state of fakes, emitted events), and verify interactions only where the interaction *is* the behaviour (e.g. "an email is sent").

## 3. Slice tests

**`@WebMvcTest(OrderController.class)`** — always name the controller; without it, all controllers load.
- Mock the service layer with `@MockitoBean` (Boot 3.4+; `@MockBean` is deprecated in 3.4 and removed in 4.0).
- Use `MockMvcTester` (Boot 3.4+, AssertJ-style) or `MockMvc`; on Framework 7, `RestTestClient` is also available. Follow what the project uses.
- Test: request mapping, validation failures produce the expected `ProblemDetail` (status, field errors), success status + headers (`Location`), JSON shape, and security (401/403 with and without credentials). Security filters are active in `@WebMvcTest` if Spring Security is on the classpath — import your security config (`@Import(SecurityConfig.class)`) so you test real rules rather than defaults.

**`@DataJpaTest`**
- By default it replaces your DataSource with an embedded one. With Testcontainers, use `@AutoConfigureTestDatabase(replace = NONE)` plus a `@ServiceConnection` container so tests run on the real engine and your migrations run.
- Test the queries you wrote: custom JPQL/native queries, projections, specifications, constraint behaviour, optimistic locking, fetch plans. Don't test `save`/`findById` of Spring Data itself.
- Use `TestEntityManager` to set up data and `flush()`/`clear()` before asserting so you read from the DB, not the first-level cache.

## 4. Integration tests with real infrastructure

**Testcontainers + `@ServiceConnection`** (Boot 3.1+) is the standard:
- Declare containers once in a shared `@TestConfiguration` (with `@Bean @ServiceConnection` container beans) and import it into integration tests, or use a common base class. Boot wires connection details automatically — no `@DynamicPropertySource` boilerplate for supported services.
- Pin container image versions to what production runs (e.g. the same PostgreSQL major).
- Reuse containers across test classes (singleton container pattern via the shared config) — starting a DB per class is the most common cause of slow suites.
- The same `@TestConfiguration` can power local development: a test-scope `main` that calls `SpringApplication.from(Application::main).with(ContainersConfig.class)` gives developers a one-command local app with real dependencies.

**`@SpringBootTest`**:
- `webEnvironment = RANDOM_PORT` + a real HTTP client (`TestRestTemplate`, `WebTestClient`, or `RestTestClient`) for true end-to-end; `MOCK` (default) + MockMvc when you don't need a real server.
- Remember: with a real server, the test and the request run on different threads, so `@Transactional` on the test does **not** roll back what the request wrote. Clean up explicitly.
- Avoid H2 as a stand-in for the production database. If the team insists on H2 for speed, at least run the integration suite against the real engine in CI.

## 5. Mocking beans and the context cache

Spring caches application contexts between test classes keyed by their configuration. Each unique combination of `@MockitoBean`/`@MockitoSpyBean` set, `@TestPropertySource`/`properties`, active profiles, `@Import`s and context customizers creates a new context (seconds each, plus new containers if they're context-scoped).

- Standardise: a small number of base configurations/annotations for integration tests; put common `@MockitoBean`s there (e.g. for an external payment gateway) rather than varying them per class.
- `@DirtiesContext` throws the context away; use it only when a test truly corrupts shared state you can't reset.
- Prefer stubbing external systems at the HTTP boundary (WireMock) in integration tests over `@MockitoBean`-ing your own adapters — it exercises your client code and keeps the context shape stable.
- If a suite is slow, check the logs for how many times Spring Boot's banner/context startup appears before optimising anything else.

## 6. Testing security

- Use `spring-security-test`: `@WithMockUser(roles = "ADMIN")`, `@WithUserDetails`, or request post-processors (`jwt()`, `oauth2Login()`, `csrf()`, `user()`) on MockMvc requests.
- For every protected endpoint, at least: unauthenticated → 401, wrong role → 403, right role → success. Authorization regressions are silent otherwise.
- For method security (`@PreAuthorize`), test the service bean in a context where method security is enabled — a plain unit test bypasses the proxy and will always "pass".
- Test object-level authorization (user A can't read user B's resource) — the most common real-world vulnerability (IDOR/BOLA).

## 7. Testing HTTP clients, messaging, scheduling, time

- HTTP clients: `@RestClientTest` + `MockRestServiceServer`, or WireMock (also for timeouts, 5xx, malformed responses). Test your timeout and error-translation behaviour, not just the happy path.
- Messaging (Kafka, RabbitMQ): Testcontainers with `@ServiceConnection`; assert asynchronous outcomes with Awaitility, never `Thread.sleep`.
- Scheduled jobs: call the job's method directly in tests; test the schedule expression separately if it's non-trivial. Disable scheduling in most integration tests via a property-conditional configuration.
- Time: inject `Clock`; in tests provide a fixed or mutable clock bean.
- Events: `@RecordApplicationEvents` + `ApplicationEvents` to assert published events; Spring Modulith's `Scenario` API for module-level event flows.

## 8. Architecture tests

- ArchUnit rules as plain unit tests, e.g.: controllers don't access repositories; entities not referenced from web packages; no cycles between feature packages; classes annotated `@Transactional` live in service packages.
- With Spring Modulith: a single test calling `ApplicationModules.of(Application.class).verify()` enforces module boundaries, and `@ApplicationModuleTest` bootstraps one module in isolation.
- Add these early; they are cheap and prevent erosion that's expensive to undo.

## 9. Test data and isolation

- Each test sets up the data it needs (builders/factories/object mothers) and doesn't depend on order or on data left by other tests.
- Clean up between integration tests (truncate tables, or unique data per test) when you can't rely on rollback.
- Don't share mutable static state between tests.
- Keep SQL fixture scripts (`@Sql`) small and close to the test; huge shared seed files become unmaintainable.

## 10. Common failures and what they mean

| Symptom | Usual cause |
|---|---|
| `NoSuchBeanDefinitionException` in a slice test | The slice doesn't load that bean type (e.g. a service in `@WebMvcTest`) → mock it with `@MockitoBean` or `@Import` it |
| `LazyInitializationException` in tests but not locally (or vice versa) | Test is `@Transactional` while production isn't, or open-in-view differs; fix the fetch plan |
| Test passes alone, fails in the suite | Shared state or order dependence; context cache reuse with leftover data |
| Suite got much slower after a change | New context configuration variant (new `@MockitoBean` combination or property) |
| `@PreAuthorize` never enforced in test | Method security not enabled in that context, or you're calling the method directly on a non-proxied instance |
| Flyway fails only in CI | Dialect differences (H2 vs real DB) or an edited, already-applied migration |
