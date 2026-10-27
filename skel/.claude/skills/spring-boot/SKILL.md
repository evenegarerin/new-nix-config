---
name: spring-boot
description: Language-agnostic Spring Boot engineering guide covering architecture, REST APIs, persistence, transactions, configuration, security, testing, observability, and a mandatory verify-before-done loop. Use this skill whenever the task touches a Spring Boot or Spring Framework project in any way, including writing or changing controllers, services, repositories, entities, configuration (application.yml/properties), Spring Security, Spring Data, test setup, Actuator, build files that use Spring Boot starters, or reviewing, debugging, upgrading, or migrating a Spring app (e.g. Boot 2 to 3 to 4), even if the user only says "add an endpoint", "fix this bean error", "why is this query slow", or "write tests for this service" without naming Spring. Pair it with the language skill (Java or Kotlin) for syntax and idioms; this skill deliberately contains no language-specific rules.
---

# Spring Boot

This skill tells you how to build and change Spring Boot applications the way a careful senior engineer would. It covers the framework only. Language idioms (null handling, data classes vs. records, Lombok, coroutines, formatting) belong to the separate Java or Kotlin skill; read that one too.

The skill is organised as this file (the workflow and the rules that matter on almost every task) plus reference files you open only when the task needs them:

| Read when the task involves...                                   | File                              |
| ---------------------------------------------------------------- | --------------------------------- |
| Controllers, DTOs, validation, errors, API versioning, HTTP clients | `references/web-and-api.md`     |
| Entities, repositories, queries, transactions, migrations, locking | `references/data-and-transactions.md` |
| Writing or fixing tests, test slices, Testcontainers, context caching | `references/testing.md`        |
| Authentication, authorization, CORS/CSRF, secrets, hardening      | `references/security.md`         |
| Config properties, profiles, logging, Actuator, metrics, tracing, shutdown, containers | `references/config-and-operations.md` |
| Upgrading Boot versions or code that "suddenly" breaks after an upgrade | `references/version-migration.md` |
| Reviewing a PR / existing code for Spring problems               | `references/review-checklist.md` |

## 1. Orient before you write anything

Most bad AI-generated Spring code is not wrong in general; it is wrong *for this project*. It uses `javax.*` in a Jakarta project, adds a second error-handling style next to an existing one, or invents a package layout the team never used. So spend the first minutes reading, not writing.

1. **Find the Spring Boot version.** Look at the build file (parent/BOM/plugin version). The major version changes what is correct:
   - **2.x**: `javax.*` namespace, Spring Security 5 style, `@MockBean`. End of OSS support; suggest upgrading but don't silently do it.
   - **3.x**: `jakarta.*`, Spring Security 6 (lambda DSL, `SecurityFilterChain` beans), `ProblemDetail`, `RestClient` (3.2+), `@ServiceConnection` (3.1+), virtual threads (3.2+), `@MockitoBean` replacing `@MockBean` (3.4+), structured logging (3.4+).
   - **4.x**: Spring Framework 7, modularised starters and auto-configuration, Jackson 3 by default, JSpecify null-safety annotations, first-class API versioning, built-in retry/concurrency-limit annotations, HTTP service client groups. Removed APIs that were deprecated in 3.x.
   If an API you want to use doesn't exist in the detected version, use the version-appropriate alternative rather than bumping the version as a side effect. See `references/version-migration.md`.
2. **Detect the stack**: MVC (servlet) or WebFlux (reactive)? JPA, JDBC, jOOQ, R2DBC, Mongo? Flyway or Liquibase? Which security model (session, JWT resource server, OAuth2 login)? Don't mix paradigms: never add blocking calls inside a reactive pipeline, and don't introduce WebFlux into an MVC app just to get `WebClient` (use `RestClient` instead).
3. **Learn the house conventions** from 2–3 existing features: package layout, naming (`*Service`, `*Handler`, `*UseCase`?), how DTOs are mapped (hand-written, MapStruct, other), how errors are returned, how tests are written. Follow what's there even if this skill prefers something else; flag the difference instead of creating a second style. Consistency inside a codebase beats any individual "best practice".
4. **Find the build and test commands** (`./mvnw verify`, `./gradlew check`, a Makefile/Taskfile, CI config). You will need them in step 4 of the workflow.
5. **Check for project instructions** (CLAUDE.md, AGENTS.md, CONTRIBUTING, ADRs). They override this skill.

## 2. The workflow for any change

1. **Orient** (above).
2. **Plan the slice**: which layers change, what the API contract is, what the transaction boundary is, which tests prove it. For anything touching the DB schema, plan the migration first.
3. **Implement** following the rules below and the relevant reference file.
4. **Verify** — not optional. See section 9. Never report a task as done if you haven't compiled and run the relevant tests, and if you couldn't (no build tool, no network), say so explicitly.

## 3. Architecture and structure

- **Package by feature, not by layer**, for anything beyond a toy: `order/`, `customer/`, `billing/`, each containing its own web, service, persistence and DTO types. Layer-first (`controller/`, `service/`, `repository/`) scatters every feature across the tree and makes boundaries invisible. If the project is already layer-first, stay consistent.
- **Keep the main application class in the root package** so component scanning covers everything without `scanBasePackages` hacks.
- **Layer responsibilities**:
  - *Web* (controllers): HTTP mapping, input validation, DTO ↔ domain conversion, status codes. No business rules, no repository calls, no transactions.
  - *Service / application*: use-case orchestration, business rules, transaction boundaries, authorization decisions that depend on data.
  - *Persistence*: repositories and entities. No HTTP concepts, no DTOs leaking in.
- **Feature boundaries are real**: one feature calls another through its public service API (or events), never by reaching into the other feature's repository or entities. Make internals package-private where the language allows it. For modular monoliths, Spring Modulith can verify these boundaries in a test and gives you `@ApplicationModuleListener` for event-driven decoupling.
- **Enforce architecture with a test**, not with hope: ArchUnit rules (e.g. "controllers don't depend on repositories", "no cycles between features") or Spring Modulith's `verify()`. A rule nobody checks erodes within months.
- **Don't add interfaces by reflex.** An interface with exactly one implementation and no test seam or alternative implementation in sight is noise; Spring proxies classes fine. Add the interface when there's a real second implementation, a module boundary, or a port/adapter design the team uses.
- **Shared/common packages only for truly cross-cutting code** (error handling, config, security, utilities with no domain owner). A growing `common/` or `util/` package is a sign domain logic is homeless.

## 4. Dependency injection and beans

- **Constructor injection only.** Dependencies immutable, no field or setter injection for required collaborators. With a single constructor, no `@Autowired` is needed. This makes dependencies explicit, enables plain unit tests without Spring, and surfaces cycles at startup.
- **A constructor with many dependencies (≈5+) is a design smell** — the class is doing too much. Split it rather than hiding the smell.
- **Circular dependencies**: fix the design (extract a third component, use events). Don't reach for `@Lazy` or `spring.main.allow-circular-references=true`.
- **Stereotypes**: `@RestController`/`@Controller`, `@Service`, `@Repository` (when it's not a Spring Data interface), `@Component` for the rest. `@Configuration` classes hold `@Bean` methods for third-party objects and wiring.
- **Prefer auto-configuration and properties over custom beans.** Before defining your own `ObjectMapper`, `DataSource`, `RestClient.Builder`, or `SecurityFilterChain` defaults, check whether a property or a `*Customizer` bean does the job. Replacing an auto-configured bean silently drops all of Boot's defaults (e.g. a hand-built `ObjectMapper` loses module registration and `spring.jackson.*` properties).
- **Inject a clock** (`Clock` bean) instead of calling "now" directly, and inject ID/randomness sources where tests need determinism.
- **Self-invocation bypasses proxies.** Calling a `@Transactional`, `@Async`, `@Cacheable`, `@Retryable` or `@PreAuthorize` method from within the same bean does nothing. Move the method to another bean. This is one of the most common silent bugs; check for it whenever you add such an annotation.
- **Proxy-based annotations only work on public (or at least non-private), overridable methods** invoked through the Spring proxy. Classes/methods must be proxyable (relevant in languages where classes are final by default — the Kotlin skill covers the `allopen`/`plugin.spring` part).

## 5. Web layer essentials

Details and examples in `references/web-and-api.md`. The rules that apply to almost every endpoint:

- **Never expose entities over HTTP.** Use dedicated request and response DTOs. Entities leak internal fields, trigger lazy-loading during serialization, couple your API to your schema, and enable mass-assignment bugs.
- **Validate at the edge** with Bean Validation (`@Valid`/`@Validated` + constraints on DTOs). Validate business invariants again in the service; edge validation is about shape, the service about meaning.
- **One error format for the whole API: RFC 9457 `ProblemDetail`** (the successor to RFC 7807), via a single `@RestControllerAdvice` (extend `ResponseEntityExceptionHandler` so Spring's own exceptions use the same format) or `spring.mvc.problemdetails.enabled=true`. Never return stack traces, SQL messages, or class names to clients.
- **Correct status codes**: 201 + `Location` for creation, 204 for no-content, 400 for malformed input, 404 for missing, 409 for conflicts (incl. optimistic lock failures), 422 if the team uses it for semantic validation. Don't return 200 with `{"error": ...}`.
- **Paginate every collection endpoint** and cap the page size (`spring.data.web.pageable.max-page-size`). Return a stable page DTO instead of serializing Spring's `PageImpl` directly (use `@EnableSpringDataWebSupport(pageSerializationMode = VIA_DTO)` or your own wrapper).
- **Outbound HTTP**: `RestClient` for synchronous code, declarative HTTP interfaces (`@HttpExchange`) for typed clients, `WebClient` only in reactive apps. **Always set connect and read timeouts** — the default is effectively "wait forever", which turns a slow dependency into a thread-pool outage.

## 6. Persistence and transactions essentials

Details in `references/data-and-transactions.md`. Core rules:

- **`spring.jpa.open-in-view=false`.** It's `true` by default (with a startup warning) and holds a DB connection for the entire request, hiding lazy-loading bugs until production load. Load what you need inside the transaction.
- **Schema changes go through Flyway or Liquibase migrations.** `ddl-auto` is `validate` or `none` outside throwaway prototypes; never `update`/`create-drop` against a shared database. Never edit a migration that has been applied anywhere; add a new one.
- **Transactions belong on the service layer**, not controllers or repositories. Use `@Transactional(readOnly = true)` for read paths. Keep transactions short: **no remote HTTP calls, message sends, or file I/O inside a DB transaction** — use `@TransactionalEventListener(phase = AFTER_COMMIT)` or an outbox for side effects that must follow a commit.
- **Know the rollback rule**: by default only unchecked exceptions roll back. If the codebase throws checked exceptions from transactional methods, set `rollbackFor` deliberately.
- **Hunt N+1 queries**: default associations to `LAZY`, fetch what a use case needs with fetch joins, `@EntityGraph`, or DTO projections. For read-heavy endpoints, query directly into DTO/interface projections instead of loading entities.
- **No unbounded queries.** Anything that can grow returns `Page`/`Slice`/a stream with limits. `findAll()` on a production table is a latent OOM.
- **Concurrency**: add `@Version` (optimistic locking) to entities that are edited concurrently and map the conflict exception to 409.

## 7. Configuration essentials

Details in `references/config-and-operations.md`.

- **Typed configuration**: group related settings into `@ConfigurationProperties` classes with `@Validated` constraints so bad config fails at startup, not at 3 a.m. Prefer them over scattered `@Value`. Register with `@ConfigurationPropertiesScan` or `@EnableConfigurationProperties`. Add the configuration-processor dependency for IDE metadata.
- **No secrets in the repo** — not in `application.yml`, not in test resources that hit real systems. Use environment variables, a secret manager, Kubernetes secrets / config trees (`spring.config.import=configtree:...`), or Vault. Provide placeholders with no defaults for secrets so a missing secret fails fast.
- **Profiles for environment differences, not for feature flags**, and keep them few (`local`, `test`, maybe `prod`). Production config should come from the environment, not from a `prod` profile file full of hard-coded hosts.
- **Local dev with `spring-boot-docker-compose`** (or Testcontainers at dev time) so `run` brings up the database automatically with zero manual connection config.

## 8. Testing essentials

Details in `references/testing.md`.

- **Test pyramid in Spring terms**: plain unit tests for services (no Spring context, constructor-inject mocks/fakes) → slice tests (`@WebMvcTest`, `@DataJpaTest`, `@JsonTest`, `@RestClientTest`) → a few `@SpringBootTest` integration tests for critical flows.
- **Real infrastructure, not H2**: use Testcontainers with `@ServiceConnection` for databases, brokers, caches. H2 "compatibility mode" hides dialect, constraint, locking and migration bugs.
- **Protect the context cache**: every distinct combination of `@MockitoBean`s, properties and profiles creates a new application context. Share a base configuration for integration tests and avoid `@DirtiesContext` unless truly necessary; slow suites are usually a context-cache problem.
- **Test behaviour through the public contract**: for controllers assert status, headers, and JSON body (including error `ProblemDetail`s); for repositories test the custom queries you wrote, not Spring Data's `save`.
- **Write the test for a bug before fixing it** whenever you're fixing a bug.

## 9. Verify before you say "done"

Run this loop after every non-trivial change and fix what it reports before handing back:

1. **Compile/build**: the project's own wrapper (`./mvnw` / `./gradlew`), not a globally installed tool.
2. **Run the tests closest to the change**, then the full suite if feasible (`verify` / `check`, which also runs static analysis the project configured).
3. **Start the app if the change touches wiring, config, security or migrations** — many Spring errors (bean cycles, missing properties, failing migrations, ambiguous mappings) only appear at startup. Check the log for warnings like the open-in-view warning or deprecated properties.
4. **Diff review**: read your own diff against `references/review-checklist.md` — especially proxies/self-invocation, transaction boundaries, entity exposure, unbounded queries, missing timeouts, secrets, and missing tests.
5. **Report honestly**: what you ran, what passed, what you could not run and why.

If tests fail for reasons unrelated to your change, say so and don't "fix" them by deleting or `@Disabled`-ing tests.

## 10. Things to never do

- Expose JPA entities as API request/response bodies.
- Put `@Transactional` on controllers, or make remote calls inside a transaction.
- Catch exceptions and return `null`/empty to "handle" them; let them reach the advice or translate them meaningfully.
- Log secrets, tokens, passwords, full request bodies with personal data, or full card/ID numbers.
- Disable CSRF, open `permitAll()` broadly, or turn off TLS verification to "make it work" — find the actual cause. (CSRF *can* legitimately be off for stateless token-authenticated APIs; see `references/security.md`.)
- Use `ddl-auto=update` against a real database or edit applied migrations.
- Expose all Actuator endpoints publicly (`management.endpoints.web.exposure.include=*` on the public port).
- Introduce a new library (MapStruct, Modulith, a resilience lib, a different JSON lib) without checking whether the project already has an equivalent, and without mentioning it to the user.
- Silently upgrade the Spring Boot version as part of an unrelated task.
- Copy an outdated Stack Overflow pattern (`WebSecurityConfigurerAdapter`, `RestTemplate` for new code, `@MockBean` on Boot 3.4+, `javax.*` on Boot 3+) — check against the detected version.

## 11. When asked to scaffold a new project

Use start.spring.io's defaults (or the Spring Boot CLI/IDE initializer) rather than hand-writing the build file, pick the latest stable Spring Boot release (verify it, don't assume from memory), and include from the start: Actuator, validation, the chosen data starter plus Flyway/Liquibase, Testcontainers with `@ServiceConnection`, Docker Compose support for local dev, `open-in-view=false`, a `ProblemDetail`-based error handler, structured logging, and an architecture test. A minimal feature (one entity end-to-end with tests) is a better skeleton than empty packages.
