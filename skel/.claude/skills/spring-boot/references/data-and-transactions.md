# Data access and transactions

## Contents
1. Baseline settings
2. Entity design
3. Repositories and queries
4. N+1 and fetching
5. Transactions: boundaries, propagation, pitfalls
6. Side effects after commit, events, outbox
7. Concurrency and locking
8. Schema migrations
9. Connection pool and performance
10. When not to use JPA

## 1. Baseline settings

```yaml
spring:
  jpa:
    open-in-view: false            # hold connections only inside transactions
    hibernate:
      ddl-auto: validate           # schema comes from migrations; validate catches mapping drift
    properties:
      hibernate:
        jdbc.batch_size: 50        # enable JDBC batching for bulk writes
        order_inserts: true
        order_updates: true
```

- Don't enable `spring.jpa.show-sql` in shared config; use `logging.level.org.hibernate.SQL=debug` (and the bind-parameter logger) locally only. Bind parameters can contain personal data.
- Turn on Hibernate statistics or a query-count assertion in tests when chasing performance issues.

## 2. Entity design

- Entities model persistence, not API. Keep them out of controllers (see web reference).
- **Identifiers**: follow the project. For new projects, either DB sequences (`SEQUENCE` generation with an allocation size — works with batching) or application-generated UUIDs (prefer time-ordered UUIDs, e.g. v7, for index locality). `IDENTITY` generation disables insert batching.
- **equals/hashCode**: don't base them on mutable fields or on all fields; never include lazy associations. Use a stable business key, or the id with care for transient (unsaved) entities. The language skill covers the syntax; the rule is about JPA semantics.
- **Associations**: `@ManyToOne` and `@OneToOne` default to EAGER — set them to `LAZY` explicitly. Collections are lazy by default; keep them that way.
- **Avoid bidirectional associations unless you navigate both ways**; when you do, maintain both sides in helper methods on the owning aggregate.
- **Don't map huge collections** (`@OneToMany` over thousands of rows). Query them with pagination instead.
- **Cascade deliberately**: `CascadeType.ALL`/`orphanRemoval` only within one aggregate (parent owns children's lifecycle). Never cascade REMOVE across aggregates.
- **Enums**: `@Enumerated(EnumType.STRING)`, never ORDINAL (reordering the enum corrupts data).
- **Auditing**: `@EnableJpaAuditing` + `@CreatedDate`/`@LastModifiedDate`/`@CreatedBy` instead of setting timestamps by hand. Store instants in UTC.
- Entity classes need a no-arg constructor and must be proxyable (non-final); the language skill explains how in that language.

## 3. Repositories and queries

- Extend `JpaRepository` (or `ListCrudRepository`/`CrudRepository` for a narrower surface). Keep repositories per aggregate root, not per table.
- Derived query methods are fine for simple lookups (`findByEmail`). When a name gets longer than ~3 conditions, write `@Query` with JPQL or a native query — readable beats clever.
- **Always use parameters** (`:name` / `?1`), never concatenate strings into JPQL/SQL. Same for `JdbcClient` and native queries.
- **Projections for reads**: interface or DTO projections (`select new ...` in JPQL, or DTO types in derived queries) load only needed columns and avoid dirty-checking overhead.
- Return `Optional` (or nullable per language skill) for single results, and map "absent" to a domain `NotFound` exception in the service.
- Bulk updates/deletes: `@Modifying @Query("update ...")` with `clearAutomatically = true` when entities of that type may be in the persistence context. Don't load 10,000 entities to change one column.
- `JdbcClient` (Boot 3.2+) is a good choice for reporting queries, bulk operations or anything where an ORM adds nothing. Mixing it with JPA in the same transaction works (same DataSource), but flush the persistence context before raw SQL reads entities you just modified.
- Streaming large results: `Stream<T>` return types require an open transaction and must be closed; for batch processing prefer paged/keyset loops with `clear()` between pages.

## 4. N+1 and fetching

N+1 is the most common JPA performance bug: loading N parents then lazily touching each one's association issues N extra queries.

- Decide fetching **per use case**, not globally on the mapping:
  - `JOIN FETCH` in JPQL for a specific query,
  - `@EntityGraph(attributePaths = {...})` on repository methods,
  - DTO projections that join exactly what's needed.
- Don't fetch-join more than one collection in the same query (Cartesian product, and Hibernate refuses multiple bags). Fetch the second collection in a separate query or use `@BatchSize`/`hibernate.default_batch_fetch_size` (e.g. 50–100) as a global safety net.
- Paging with a collection fetch-join paginates in memory (Hibernate warns `HHH90003004`). Page the parent ids first, then fetch those parents with their collections.
- Add a test that asserts query counts for important read paths if the team has a tool for it (e.g. a datasource proxy).

## 5. Transactions

**Where**: on service methods (the use-case boundary). Class-level `@Transactional(readOnly = true)` with method-level `@Transactional` on writes is a clean default.

**Why readOnly matters**: it lets Hibernate skip dirty checking and flushing, and lets routing data sources send reads to replicas.

**Pitfalls to check every time:**
- **Self-invocation**: calling a transactional method from another method in the same bean bypasses the proxy, so the annotation is ignored. Move it to another bean.
- **Private/final methods** are not proxied; the annotation silently does nothing.
- **Checked exceptions don't roll back by default.** Either use unchecked exceptions for failures or specify `rollbackFor`.
- **Catching an exception inside a transaction** after a JPA error still leaves the transaction marked rollback-only → `UnexpectedRollbackException` later. Don't catch-and-continue around persistence failures.
- **Long transactions**: no HTTP calls, no sleeps, no user interaction, no large file processing inside. Load → decide → write → commit; do the slow work before or after.
- **`REQUIRES_NEW`** suspends the outer transaction and takes a second connection; heavy use can deadlock a small pool. Use it for things like audit logs that must persist even if the outer work fails, and know that cost.
- **`@Transactional` on tests** rolls back after each test — convenient, but it hides flush-time errors and lazy-loading issues that occur outside a transaction in production, and it doesn't apply to code running on other threads (e.g. `@SpringBootTest(webEnvironment = RANDOM_PORT)` requests). For integration tests through HTTP, clean up data explicitly instead.
- **Async + transactions**: a transaction doesn't propagate to `@Async` methods or other threads.

Programmatic `TransactionTemplate` is fine (and clearer) when only part of a method should be transactional.

## 6. Side effects after commit, events, outbox

Problem: you save an order and send an email/publish a message inside the same method. If the commit fails, the message is already out; if the message send is slow, the transaction holds locks.

- For in-process follow-up work: publish an application event and handle it with `@TransactionalEventListener(phase = AFTER_COMMIT)` (combine with `@Async` if it shouldn't block the caller). Spring Modulith's `@ApplicationModuleListener` packages this pattern and can persist events in an event publication registry so they survive crashes.
- For messages to other systems that must not be lost: transactional outbox (write the message to an outbox table in the same transaction; a relay publishes it). Don't attempt distributed two-phase commits.
- Make consumers idempotent; at-least-once delivery is the norm.

## 7. Concurrency and locking

- **Optimistic locking**: add a `@Version` field to aggregates edited concurrently (most of them). Map `OptimisticLockingFailureException` to 409 and let clients retry with fresh data. Expose the version as an ETag for HTTP-level conditional updates if the API needs it.
- **Pessimistic locking** (`@Lock(PESSIMISTIC_WRITE)`) only for short critical sections with real contention (counters, inventory reservation); always within a transaction, and set a lock timeout.
- **Unique constraints in the database**, not just "check then insert" in code — the check is a race. Translate the resulting `DataIntegrityViolationException` to 409.
- Scheduled jobs in multi-instance deployments run on every instance; use ShedLock or a DB-based lock, or a dedicated scheduler.

## 8. Schema migrations

- Use **Flyway** (SQL-first, simple) or **Liquibase** (changelogs, rollbacks); keep whichever the project has.
- Migrations live in the default location (`db/migration` for Flyway), are versioned, and are **immutable once merged**. Fix mistakes with a new migration.
- Write migrations that are **backward compatible with the running version** of the app for zero-downtime deploys: expand (add nullable column / new table) → deploy code that writes both → backfill → contract (drop old) in a later release. Never rename/drop a column in the same release that stops using it.
- Big table changes: create indexes concurrently where the database supports it, batch backfills, avoid long locks.
- Add indexes for foreign keys and for columns used in frequent `WHERE`/`ORDER BY` clauses; the ORM won't do it for you.
- Test migrations against the real database engine via Testcontainers (the integration tests do this automatically if Flyway/Liquibase runs on startup).

## 9. Connection pool and performance

- HikariCP is the default. Pool size is not "bigger is better": start around `(cores * 2) + effective_spindle_count`-ish (≈10 for typical services) and measure. Too large a pool overloads the database.
- With virtual threads, many more requests may wait on the pool simultaneously; the pool, not the thread count, becomes the limiter. Set `connection-timeout` so callers fail fast instead of queueing forever.
- Watch the Actuator/Micrometer `hikaricp.*` metrics (pending connections, usage time).
- Caching (`@Cacheable`): cache read-mostly, expensive lookups; always define TTL/size in the cache provider (Caffeine/Redis) — the default simple cache never evicts. Mind self-invocation, and never cache entities that will be modified (detached entity problems); cache DTOs.

## 10. When not to use JPA

JPA shines for aggregate-oriented write models. For reporting, analytics, bulk ETL, or heavily SQL-shaped workloads, `JdbcClient`, Spring Data JDBC, or jOOQ are often simpler and faster. Don't introduce a new data technology without asking, but don't force everything through entities either.
