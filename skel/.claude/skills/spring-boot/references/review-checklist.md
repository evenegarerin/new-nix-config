# Spring Boot review checklist

Use this for reviewing someone's PR, auditing existing code, or self-reviewing your own diff in the verification loop. Report findings ranked by severity (🔴 must fix: bugs, security, data loss · 🟡 should fix: performance, maintainability risks · 🟢 nice to have), each with the file/line, *why* it matters, and a concrete fix. Don't pad the review with style nits the formatter or language skill already covers, and acknowledge what's done well when it's notable.

## Correctness and Spring semantics
- [ ] `@Transactional`/`@Async`/`@Cacheable`/`@Retryable`/`@PreAuthorize` methods are called through the proxy (no self-invocation) and are not private/final.
- [ ] Transaction boundaries sit on the service layer; read paths use `readOnly = true`.
- [ ] No remote calls, message publishing, or slow I/O inside DB transactions; post-commit side effects use `@TransactionalEventListener(AFTER_COMMIT)` or an outbox.
- [ ] Checked exceptions in transactional methods roll back if they should (`rollbackFor`).
- [ ] No exceptions swallowed inside transactions (rollback-only surprises).
- [ ] Constructor injection; no field injection; no circular dependencies papered over with `@Lazy`.
- [ ] Auto-configured beans not replaced unnecessarily (custom `ObjectMapper`, `DataSource`, etc.).
- [ ] APIs match the project's Boot version (no `javax` on 3+, no `@MockBean` on 3.4+/4, no `WebSecurityConfigurerAdapter`, no new `RestTemplate` code).

## API layer
- [ ] No entities in request/response bodies; separate request and response DTOs.
- [ ] Input validated with Bean Validation; nested objects cascade with `@Valid`.
- [ ] Errors use the project's single error format (ProblemDetail); no stack traces/SQL in responses.
- [ ] Correct status codes (201 + Location, 204, 404, 409...).
- [ ] Collection endpoints paginated with a max page size; sort fields whitelisted.
- [ ] Breaking contract changes avoided or versioned.

## Persistence
- [ ] `open-in-view=false`; no reliance on lazy loading outside transactions.
- [ ] No N+1: fetch joins / entity graphs / projections for the use case; `@ManyToOne`/`@OneToOne` are `LAZY`.
- [ ] No unbounded `findAll()` or result lists that can grow without limit.
- [ ] Schema changes come with a new migration; no edited applied migrations; `ddl-auto` is `validate`/`none`.
- [ ] Migration is backward compatible with the currently deployed version.
- [ ] Indexes exist for new FK/filter/sort columns.
- [ ] `@Version` on concurrently edited aggregates; uniqueness enforced by DB constraints.
- [ ] Enums stored as STRING; queries parameterized.

## Security
- [ ] Every new endpoint is covered by an explicit authorization rule; the chain is deny-by-default.
- [ ] Object-level authorization: resource access is scoped to the caller/tenant.
- [ ] CSRF only disabled for stateless token APIs; CORS origins explicit.
- [ ] No secrets in code, config, tests, or logs; passwords hashed with a delegating/bcrypt/argon2 encoder.
- [ ] No user-controlled URLs, file paths, or sort expressions used without validation/allow-lists.
- [ ] Actuator exposure limited; sensitive endpoints not public.

## Resilience and operations
- [ ] Outbound HTTP clients have connect/read timeouts and are built from the auto-configured builders.
- [ ] Retries only on idempotent operations, with backoff and limits, not stacked across layers.
- [ ] Configuration is typed (`@ConfigurationProperties` + validation), not scattered `@Value`s; new properties documented.
- [ ] Logging: right levels, no log-and-rethrow, no sensitive data; metrics tags low-cardinality.
- [ ] Scheduled jobs safe to run on multiple instances (lock) and idempotent.
- [ ] `@Async`/executors are Spring-managed and bounded.

## Tests
- [ ] New behaviour has tests at the cheapest effective level (unit → slice → integration).
- [ ] Integration tests use real infrastructure (Testcontainers + `@ServiceConnection`), not H2 substitutes.
- [ ] Security rules tested (401/403/allowed) including object-level access.
- [ ] Error paths tested (validation errors, not found, conflict), not only happy paths.
- [ ] No new context-cache variants without need; no `@DirtiesContext` by habit; no `Thread.sleep` for async assertions.
- [ ] Bug fixes include a regression test.

## Architecture
- [ ] Code placed in the right feature package following the project's structure.
- [ ] No cross-feature access to another feature's repositories/entities.
- [ ] No new libraries added without need and without mention.
- [ ] Architecture tests (ArchUnit/Modulith) still pass and cover new packages.
