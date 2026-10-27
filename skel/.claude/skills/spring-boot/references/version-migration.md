# Version awareness and migrations

Spring changes enough between major versions that code copied from memory is often wrong for the project at hand. Always check the version first (build file), and when you're unsure whether an API exists in that version, check the official reference docs or release notes for that exact version instead of guessing. Today's facts drift: verify the current latest version online when scaffolding or upgrading.

## Quick recognition guide

| You see... | You're on... | Watch out for |
|---|---|---|
| `javax.persistence`, `javax.validation`, `WebSecurityConfigurerAdapter`, `spring.redis.*` | Boot 2.x | Out of OSS support; don't add 3.x APIs |
| `jakarta.*`, `SecurityFilterChain`, `ProblemDetail`, `RestClient` | Boot 3.x | `@MockBean` deprecated in 3.4 → `@MockitoBean` |
| Spring Framework 7, Jackson 3 (`tools.jackson` packages), modular `spring-boot-*` auto-config modules, `@ImportHttpServices`, `RestTestClient` | Boot 4.x | Removed 3.x deprecations; renamed starters; test slices in separate test starters |

## General upgrade procedure

1. **Upgrade one minor/major step at a time** (e.g. 3.3 → 3.5 → 4.0), never skipping majors. Get to the latest patch of the current line first.
2. **Fix all deprecation warnings before a major upgrade**; the next major removes them.
3. Add `spring-boot-properties-migrator` temporarily (runtime scope): it reports and temporarily remaps renamed/removed configuration properties at startup. Remove it after migrating.
4. Use OpenRewrite's Spring Boot migration recipes where possible for the mechanical parts (namespace changes, renamed APIs); review the diff, don't trust it blindly.
5. Read the official migration guide / release notes for each version (the Spring Boot GitHub wiki "Spring Boot X.Y Release Notes" and the "Migration Guide" pages).
6. Upgrade third-party libraries that integrate with Spring (springdoc, MapStruct, Testcontainers, Resilience4j, Modulith...) to versions compatible with the new Boot line.
7. Run the full verification loop (build, all tests, start the app, smoke-test key endpoints).
8. Do the upgrade as its own change, separate from feature work.

## Boot 2 → 3 highlights

- Java 17 baseline; `javax.*` → `jakarta.*` everywhere (persistence, validation, servlet, annotations, transaction).
- Spring Security 6: `SecurityFilterChain` beans, `authorizeHttpRequests`, `requestMatchers`, lambda DSL.
- Hibernate 6: changes in ID generation defaults, some HQL behaviour and type mappings — test queries and migrations.
- Trailing-slash matching disabled by default (`/orders/` no longer matches `/orders`).
- Property renames (e.g. `spring.redis.*` → `spring.data.redis.*`) — use the properties migrator.
- Micrometer Observation + Micrometer Tracing replace Spring Cloud Sleuth.
- `spring.factories` for auto-configuration → `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.

## Boot 3.x → 4 highlights (verify details against the official migration guide)

- Spring Framework 7 and Jakarta EE 11 baseline.
- **Modularisation**: auto-configuration split into focused modules and starters; some starters renamed (e.g. a dedicated `webmvc` starter), and test support split into per-technology test starters. Missing classes after upgrade often mean a missing module/starter rather than a removed feature.
- **Jackson 3** is the default JSON library (new `tools.jackson` package names, some changed defaults); Jackson 2 support remains in a deprecated form for transition. Custom serializers/modules and `ObjectMapper` customisations need review.
- **Null-safety** with JSpecify annotations across the Spring portfolio — affects tooling and languages with null-aware type systems (see the language skill).
- **API versioning** support built into Spring MVC/WebFlux.
- **HTTP service clients**: `@ImportHttpServices` groups with property-based configuration.
- **Resilience** features in core: `@Retryable`, `@ConcurrencyLimit` (enable with `@EnableResilientMethods`).
- **Testing**: `@MockBean`/`@SpyBean` removed (use `@MockitoBean`/`@MockitoSpyBean`); `RestTestClient` added.
- APIs deprecated during 3.x are removed — fix deprecations first.

## Boot 4.0 → 4.1 highlights

- Removes 4.0 deprecations; `layertools` jar mode removed (use the `tools` jar mode).
- Spring gRPC support, Jackson configuration property updates, HTTP client SSRF mitigation via address filtering, OpenTelemetry updates.

## When you're asked to "just fix it" after an upgrade

Map the error to its likely cause before changing code:
- `ClassNotFoundException`/missing auto-configuration → missing modular starter or changed artifact name.
- Beans not created that used to be → conditions changed or a property was renamed (check the properties migrator output and the `conditions` Actuator endpoint / `--debug` report).
- JSON shape changed → Jackson default changes; configure via `spring.jackson.*` rather than rewriting DTOs.
- 404s on URLs with trailing slashes (2→3) → clients must use canonical URLs; don't globally re-enable trailing slash matching without discussing.
- Security rules behave differently → re-read the matcher semantics for the new version and test 401/403 paths.
