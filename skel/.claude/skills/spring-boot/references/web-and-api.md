# Web layer and API design

## Contents
1. Controller shape
2. DTOs and mapping
3. Validation
4. Error handling with ProblemDetail
5. Status codes and response conventions
6. Pagination, sorting, filtering
7. API versioning
8. Outbound HTTP clients
9. Reactive (WebFlux) notes

## 1. Controller shape

A controller method should read like a translation table: take validated input, call one service method, map the result to a response. If a controller method has branches about business state, loops over domain objects, or touches a repository, that logic belongs in the service.

- `@RestController` + `@RequestMapping("/api/orders")` at class level; method mappings with `@GetMapping`, `@PostMapping`, etc.
- Use `ResponseEntity` only where you need to control status/headers (201 + `Location`, conditional responses); otherwise return the body and use `@ResponseStatus` for non-200 fixed statuses.
- Path variables for identity (`/orders/{id}`), query params for filtering/paging, body for state. Nouns in paths, plural collections, no verbs (`/orders/{id}/cancel` as a POST sub-resource action is acceptable when the operation isn't a plain state update).
- Don't accept `Map<String, Object>` or the raw request as input "for flexibility" — it disables validation and documentation.
- Inject the authenticated principal with `@AuthenticationPrincipal` rather than reading the security context manually in business code.

## 2. DTOs and mapping

- Separate request DTOs (what clients may send) from response DTOs (what they get). A single DTO for both invites clients to send `id`, `createdAt`, or `status` and have it accepted.
- Make DTOs immutable value types (the language skill says which construct).
- Mapping: follow the project. Hand-written mapping functions are fine and explicit; MapStruct is fine if already present. Mapping lives at the edge (controller or a mapper next to it), not inside entities and not in repositories.
- Use DTO/interface projections for read endpoints so you don't load entities just to copy fields.
- Never serialize entities: lazy associations explode, bidirectional relations recurse, internal fields leak.

## 3. Validation

- Annotate request DTO fields with constraints (`@NotBlank`, `@Size`, `@Email`, `@Positive`, `@Pattern`, `@Future`...). Trigger with `@Valid` on the `@RequestBody` parameter.
- Validate path/query parameters with constraints directly on the method parameters; in Spring Framework 6.1+ MVC applies method validation to controllers automatically when constraints are present (no `@Validated` on the class needed for that case), and failures surface as `HandlerMethodValidationException`.
- Nested objects need `@Valid` on the field to cascade.
- Cross-field rules (start < end) → a class-level custom constraint.
- Business rules ("customer must not have unpaid invoices") belong in the service and produce a domain exception mapped to 409/422, not a Bean Validation constraint that queries the database.
- Make sure validation errors come back as a `ProblemDetail` listing the field errors, not Spring's default verbose body.

## 4. Error handling with ProblemDetail

Goal: every error response from the API has the same `application/problem+json` shape (RFC 9457): `type`, `title`, `status`, `detail`, `instance`, plus extension fields such as `errors` (field violations) or a `code` the client can switch on.

Setup:
- One `@RestControllerAdvice` that extends `ResponseEntityExceptionHandler`. Extending it means Spring MVC's own exceptions (malformed JSON, missing params, method not allowed, validation failures) already produce `ProblemDetail`s; you only add handlers for your domain exceptions and override the validation handler if you want a custom `errors` array.
- Or, at minimum, `spring.mvc.problemdetails.enabled=true` (`spring.webflux.problemdetails.enabled` for reactive).
- Domain exceptions can extend `ErrorResponseException` or implement `ErrorResponse` to carry their own status and ProblemDetail; then no handler is needed per exception.
- Keep a small, explicit exception hierarchy (`NotFound`, `Conflict`, `BusinessRuleViolation`...) instead of one exception per situation or one generic exception with a status code field everywhere.
- A catch-all handler for unexpected exceptions logs the full error server-side (with a correlation/trace id) and returns a generic 500 ProblemDetail with that id — never the exception message, which may contain SQL, file paths, or personal data.
- Map `OptimisticLockingFailureException` → 409, `AccessDeniedException` → 403 (let Spring Security handle it; don't swallow it in a generic handler), `DataIntegrityViolationException` → 409 with a sanitized message.
- `server.error.include-stacktrace=never` and `include-message`/`include-binding-errors` off in production for the fallback `/error` path.

## 5. Status codes and response conventions

| Situation | Status |
|---|---|
| Created | 201 + `Location` header pointing at the new resource |
| Accepted for async processing | 202 + a way to poll status |
| Success with no body (delete, some updates) | 204 |
| Malformed / failed validation | 400 |
| Not authenticated | 401 (with `WWW-Authenticate` for token APIs) |
| Authenticated but not allowed | 403 |
| Not found (or hidden for authorization reasons) | 404 |
| State conflict, duplicate, optimistic lock | 409 |
| Precondition failed (If-Match / ETag mismatch) | 412 |
| Semantically invalid (if the team uses it) | 422 |
| Rate limited | 429 + `Retry-After` |

Consistent JSON: pick one naming style (camelCase is the Jackson default) and one date format (ISO-8601 with offset; never epoch-millis-as-number unless established). Configure via `spring.jackson.*` properties or a `Jackson*BuilderCustomizer` bean, not by replacing the mapper bean.

For idempotent creation from unreliable clients (payments, orders), support an `Idempotency-Key` header and store processed keys.

## 6. Pagination, sorting, filtering

- Accept `Pageable` in the controller (with `@PageableDefault` for sensible defaults), and cap it: `spring.data.web.pageable.max-page-size=100` (or the team's number).
- Whitelist sortable properties. Passing arbitrary user-provided sort fields to JPA can error on unknown fields or expose internal columns.
- Return a stable page structure (content + page metadata). Serializing `PageImpl` directly is discouraged by Spring Data and logs a warning; use `@EnableSpringDataWebSupport(pageSerializationMode = VIA_DTO)` or your own page DTO.
- For large/infinite feeds prefer keyset/cursor pagination (`Window`/`ScrollPosition` in Spring Data, or a `WHERE id > :lastId` query) over deep OFFSET pages.
- Complex optional filters: Specifications, Querydsl, or a criteria object → explicit query. Don't build JPQL with string concatenation.

## 7. API versioning

Version only when you must break a contract; additive changes (new optional fields, new endpoints) don't need a version. When you do:
- On Spring Framework 7 / Boot 4 use the built-in API versioning support (configure the strategy — header, path segment, query param or media type — via `spring.mvc.apiversion.*` properties or `ApiVersionConfigurer`, then use the `version` attribute on mappings).
- On older versions, follow the project's existing approach (usually a `/v1/` path prefix).
- Make clients tolerant readers: ignore unknown JSON properties (Boot's default `FAIL_ON_UNKNOWN_PROPERTIES=false`) so adding fields is non-breaking.

## 8. Outbound HTTP clients

- **`RestClient`** (Boot 3.2+) for synchronous calls. Build from the auto-configured `RestClient.Builder` so you inherit observability, message converters and customizers.
- **HTTP service interfaces** (`@HttpExchange`, `@GetExchange`...) for typed clients; on Boot 4 register them as groups with `@ImportHttpServices` and configure base URLs/timeouts per group via properties. On Boot 3 create them via `HttpServiceProxyFactory`.
- **`WebClient`** only in reactive applications. **`RestTemplate`** is in maintenance mode — don't introduce it in new code; keep it where it exists unless asked to migrate.
- **Timeouts always**: connect and read timeouts via `spring.http.client.*` properties (or the request factory). Pick values from the dependency's SLA, not "30 seconds because".
- **Resilience**: retries only for idempotent operations, with backoff and a cap. Spring Framework 7 offers `@Retryable` and `@ConcurrencyLimit` in core (enable with `@EnableResilientMethods`); otherwise Spring Retry or Resilience4j (circuit breakers, bulkheads). Don't stack retries at several layers — it multiplies load on a struggling dependency.
- **Wrap external clients behind a small adapter** owned by the feature that uses them, translating remote errors into your domain exceptions. Don't let generated client models leak into the domain.
- **SSRF**: never build target URLs from user input without an allow-list. Boot 4.1+ offers address-filtering support for HTTP clients; use it where users can influence destinations (webhooks, URL previews).
- Test clients with `@RestClientTest` + `MockRestServiceServer`, or WireMock for full HTTP behaviour.

## 9. Reactive (WebFlux) notes

Only if the project is already reactive:
- Never block (`block()`, blocking JDBC/JPA, blocking I/O) on event-loop threads. If a blocking library is unavoidable, isolate it on a bounded elastic scheduler and document why.
- Use R2DBC or reactive drivers for persistence; JPA is blocking.
- Error handling with `ProblemDetail` works the same via `@RestControllerAdvice` (extend the reactive `ResponseEntityExceptionHandler`).
- Use `WebTestClient` for tests and StepVerifier for pipelines.
- For new I/O-heavy servlet apps on Java 21+, prefer MVC + virtual threads (`spring.threads.virtual.enabled=true`) over adopting WebFlux purely for scalability.
