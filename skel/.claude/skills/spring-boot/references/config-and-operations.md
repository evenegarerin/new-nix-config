# Configuration and production operations

## Contents
1. Configuration properties
2. Profiles and environments
3. Local development
4. Logging
5. Observability: Actuator, metrics, tracing
6. Health, readiness, liveness
7. Graceful shutdown and lifecycle
8. Concurrency: virtual threads, async, scheduling
9. Packaging and containers
10. Startup and performance

## 1. Configuration properties

- Group settings by feature/integration into `@ConfigurationProperties(prefix = "app.payments")` types. Make them immutable (constructor binding), validate with `@Validated` + constraints so startup fails on bad config, and give non-secret settings sensible defaults.
- Use rich types: `Duration` (`30s`, `500ms`), `DataSize` (`10MB`), URIs, enums, lists/maps — Boot converts them. Don't parse strings by hand.
- Prefix custom properties with something app-specific (`app.`, the company name) — never invent properties under `spring.`/`server.`/`management.` namespaces.
- Add the configuration processor (annotation processor / kapt-or-KSP equivalent per language skill) to get IDE autocompletion and metadata.
- `@Value` is acceptable for a single isolated value; more than two related `@Value`s means you want a properties class.
- YAML or properties: follow the project. Don't mix both for the same profile.
- Relaxed binding: env var `APP_PAYMENTS_TIMEOUT` binds to `app.payments.timeout` — document the env var names ops must set.
- `spring.config.import` for external sources (`optional:file:./config/`, `configtree:/etc/secrets/` for Kubernetes-mounted secrets, Vault/Config Server).

## 2. Profiles and environments

- Few profiles: e.g. `local` (developer conveniences) and `test`. Production values come from the environment (env vars, config maps, secret stores), so the same artifact runs everywhere.
- Don't scatter `@Profile("prod")` through business code; if behaviour differs by environment, express it as configuration (a property toggling an implementation via `@ConditionalOnProperty`).
- Profile groups (`spring.profiles.group.*`) for composing; avoid deep profile hierarchies.
- Never let a missing profile default to production-like credentials.

## 3. Local development

- `spring-boot-docker-compose`: put a `compose.yaml` in the project root and Boot starts the services and wires connection details on `run`. Zero manual JDBC URLs.
- Alternatively, Testcontainers at development time (see testing reference, `SpringApplication.from(...).with(...)`).
- `spring-boot-devtools` for restarts in local dev only (it's excluded from packaged apps automatically).
- A `README` section or task runner target (`make run`, Taskfile) for: run locally, run tests, run with containers.

## 4. Logging

- Log via SLF4J (Boot's default Logback, or Log4j2 if the project uses it). Don't add another logging framework.
- **Structured logging** (Boot 3.4+): `logging.structured.format.console=ecs` (or `logstash`/`gelf`) for machine-readable JSON in production; keep human-readable output locally.
- Use parameterized messages / structured key-values, not string concatenation.
- Levels: ERROR = needs human attention; WARN = unexpected but handled; INFO = significant business/lifecycle events, sparingly; DEBUG = diagnostic. Don't log-and-rethrow the same exception (duplicate stack traces); log where it's handled.
- Correlation: with Micrometer Tracing on the classpath, trace and span ids are added to the MDC automatically; include them in log patterns/structured output. Don't hand-roll a request-id filter if tracing is present.
- Never log secrets or sensitive personal data (see security reference). Mask where business logs must reference users.
- Change levels at runtime via the `loggers` Actuator endpoint (secured), not by redeploying.

## 5. Observability

- Add `spring-boot-starter-actuator` to every service.
- **Metrics** via Micrometer: export through the registry the platform uses (Prometheus, OTLP...). Boot instruments HTTP server/client, JDBC pool, JVM, caches, messaging automatically — don't duplicate those.
- Business metrics: inject `MeterRegistry`, or prefer the **Observation API** (`@Observed` or `Observation.createNotStarted(...)`) which yields metrics *and* traces from one instrumentation point.
- **Keep tag cardinality bounded**: never use user ids, order ids, raw URLs, or exception messages as metric tags.
- **Tracing**: Micrometer Tracing with an OpenTelemetry bridge/exporter (or the Boot 4 OpenTelemetry starter where used). Propagation works automatically for auto-configured `RestClient`/`WebClient`/`RestTemplate` builders — another reason to build clients from the injected builders. Set a sampling probability appropriate to traffic (`management.tracing.sampling.probability`).
- `info` endpoint: include build info and git info (build plugin goals) so you can tell what's deployed.

## 6. Health, readiness, liveness

- On Kubernetes, Boot exposes `/actuator/health/liveness` and `/actuator/health/readiness` (enabled automatically when running on Kubernetes; force with `management.endpoint.health.probes.enabled=true`).
- **Liveness should not include external dependencies** — a database outage must not make Kubernetes restart every pod. Put dependency checks in readiness (via health groups) only if being "not ready" actually helps (e.g. traffic can go elsewhere).
- Custom `HealthIndicator`s must be fast and time-bounded.

## 7. Graceful shutdown and lifecycle

- Graceful shutdown is enabled by default since Boot 3.4 (`server.shutdown=graceful`); configure `spring.lifecycle.timeout-per-shutdown-phase` to fit the platform's termination grace period.
- Consumers (Kafka/Rabbit listeners, schedulers) should stop taking new work and finish in-flight work on shutdown; avoid long uninterruptible tasks.
- Run startup work with `ApplicationRunner`/`@EventListener(ApplicationReadyEvent.class)`, not in constructors or `@PostConstruct` doing I/O.
- Don't call `System.exit` from application code.

## 8. Concurrency

- **Virtual threads** (Java 21+, Boot 3.2+): `spring.threads.virtual.enabled=true` makes the web server, `@Async`, scheduling and many integrations use virtual threads. Good for blocking I/O-heavy services. Caveats: the DB pool becomes the bottleneck (size it, set timeouts); avoid long `synchronized` blocks around I/O on older JDKs where that pins carrier threads (largely fixed in JDK 24+); ThreadLocal-heavy libraries may use more memory. Measure before and after.
- **`@Async`**: requires `@EnableAsync`; methods must be public, called through the proxy, and return `void` or a future type. Configure the executor (`spring.task.execution.*`) — bounded queue or virtual threads; handle exceptions from `void` async methods with an `AsyncUncaughtExceptionHandler`. Security context and transactions don't propagate automatically.
- **Scheduling**: `@EnableScheduling`; `@Scheduled` jobs are single-threaded by default (`spring.task.scheduling.pool.size`). In multi-instance deployments add a distributed lock (ShedLock) or use a job scheduler. Make jobs idempotent and observable (metrics + logs on start/finish/failure).
- Don't create raw threads or unmanaged executors; use Spring-managed executors so they shut down gracefully and get context propagation/observability.

## 9. Packaging and containers

- Build images with Cloud Native Buildpacks (`spring-boot:build-image` / `bootBuildImage`) or a multi-stage Dockerfile using layered jar extraction (`java -Djarmode=tools -jar app.jar extract --layers --launcher` on Boot 3.3+/4; the old `layertools` mode is gone in 4.1) for better caching.
- Run as non-root, with container-aware JVM memory settings (`-XX:MaxRAMPercentage`), and a health check using the Actuator endpoints.
- One artifact, configured per environment — no environment-specific builds.

## 10. Startup and performance

- Investigate slow startup with `spring.main.lazy-initialization` only as a diagnostic (it hides startup errors when left on), the `startup` Actuator endpoint (with `BufferingApplicationStartup`), and by trimming unused starters.
- Class Data Sharing (CDS / AOT cache on newer JDKs) gives cheap startup gains; GraalVM native images give large gains at the cost of build time and reflection constraints — only adopt deliberately, and test the native build in CI if you do.
- Don't tune GC/JVM flags without measurements.
