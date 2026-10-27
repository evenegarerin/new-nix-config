# Security

## Contents
1. Configuration style
2. Choosing an authentication model
3. Authorization: URL rules, method security, object-level checks
4. CSRF and CORS
5. Passwords and secrets
6. Input, output, and injection
7. Actuator and operational exposure
8. Headers, TLS, and misc hardening
9. Dependency hygiene

## 1. Configuration style

- Spring Security 6+ (Boot 3+): define one or more `SecurityFilterChain` beans using the lambda DSL. `WebSecurityConfigurerAdapter` no longer exists; don't generate it.
- Use `authorizeHttpRequests` (not the removed `authorizeRequests`) and `requestMatchers` (not `antMatchers`/`mvcMatchers`).
- **Deny by default**: list what's public explicitly, end with `.anyRequest().authenticated()` (or `denyAll()` for strict APIs). Never end with `permitAll()`.
- Order of rules matters: the first matching rule wins, so specific matchers go before general ones.
- Multiple filter chains (e.g. `/api/**` stateless JWT, `/admin/**` form login, actuator on its own port) are fine; give each a `securityMatcher` and an `@Order`.
- Prefer properties and auto-configuration (e.g. `spring.security.oauth2.resourceserver.jwt.issuer-uri`) over hand-built decoders and filters. Custom filters are a last resort; most "custom JWT filter" code found online reimplements the resource server badly.

## 2. Choosing an authentication model

- **API consumed by SPAs/mobile/other services with tokens from an identity provider** → OAuth2 Resource Server with JWT (`spring-boot-starter-oauth2-resource-server`). Validate issuer, audience, expiry; map scopes/claims to authorities with a `JwtAuthenticationConverter`.
- **Server-rendered web app or BFF** → OAuth2 Login (`oauth2-client`) or form login with server-side sessions. Tokens stay on the server; the browser gets a session cookie (`HttpOnly`, `Secure`, `SameSite`).
- **Service-to-service** → client credentials via the OAuth2 client support on `RestClient`/`WebClient`, or mTLS.
- **Issuing your own tokens** → use Spring Authorization Server rather than hand-rolling JWT issuance; don't put secrets in JWT payloads; keep access tokens short-lived.
- Stateless APIs: `sessionManagement(s -> s.sessionCreationPolicy(STATELESS))`.

## 3. Authorization

- **URL rules** for coarse access (roles per path).
- **Method security** for business-level rules: `@EnableMethodSecurity` + `@PreAuthorize` on service methods (works only through the proxy — mind self-invocation). Put complex rules in a named bean (`@PreAuthorize("@orderAccess.canView(#id, authentication)")`) rather than long SpEL strings.
- **Object-level authorization (the #1 API vulnerability, BOLA/IDOR)**: whenever a request references a resource by id, check that the caller may access *that* resource — scope queries by owner/tenant (`findByIdAndOwnerId`), or verify ownership in the service. Don't rely on ids being hard to guess.
- Return 404 instead of 403 when even revealing existence would leak information.
- Multi-tenancy: enforce the tenant filter centrally (Hibernate filters, a tenant-aware repository base, or row-level security in the DB), not per query by memory.
- Roles vs authorities: `hasRole("ADMIN")` checks the authority `ROLE_ADMIN`; JWT scopes become `SCOPE_x`. Mismatches here cause "everything is 403".

## 4. CSRF and CORS

- **CSRF**: keep it enabled for anything using cookie/session authentication (including SPAs with session cookies — use the cookie-based token repository and the SPA-friendly handler per the Spring Security docs). Disabling it is acceptable only for truly stateless APIs authenticated with bearer tokens in headers. Never disable it just to make a POST from Postman work.
- **CORS**: configure through Spring Security's `cors()` with a `CorsConfigurationSource` bean listing explicit origins, methods and headers. `allowedOrigins("*")` with credentials is invalid and unsafe; avoid wildcard origins for authenticated APIs. Don't also add a separate `WebMvcConfigurer` CORS setup that conflicts.

## 5. Passwords and secrets

- Hash passwords with `PasswordEncoderFactories.createDelegatingPasswordEncoder()` (bcrypt by default, upgradeable) or Argon2/bcrypt directly. Never MD5/SHA-x, never reversible encryption, never log them.
- Secrets (DB passwords, client secrets, signing keys, API keys) come from the environment or a secret store, never committed. Check `application*.yml`, test resources, Dockerfiles, and CI files in your diff.
- `@ConfigurationProperties` holding secrets: don't log or `toString()` them; Actuator's `/env` and `/configprops` sanitize values by default (`management.endpoint.env.show-values=never` unless deliberately changed) — keep it that way.
- Rotate on leak; removing a secret from the latest commit doesn't remove it from history.

## 6. Input, output, and injection

- **SQL/JPQL injection**: parameters only. Watch for string-built `ORDER BY` from user input — whitelist sort fields.
- **Mass assignment**: dedicated request DTOs without fields the client must not set (role, owner, price, status).
- **Deserialization**: never enable Jackson default typing / polymorphic deserialization from untrusted input without a strict allow-list.
- **SSRF**: allow-list destinations for any user-influenced outbound URL (webhooks, image fetching).
- **Path traversal**: never build file paths from user input without normalisation and a base-directory check.
- **Output**: server-side templates (Thymeleaf) escape by default — don't use unescaped output (`th:utext`) with user data. APIs return JSON with correct content type.
- **Error responses** don't include stack traces, SQL, or internal identifiers (see the ProblemDetail section in the web reference).
- **Logging**: don't log tokens, passwords, full request bodies containing personal data, or `Authorization` headers. Beware log injection (CR/LF in user input) — structured (JSON) logging mitigates it.
- **Rate limiting / brute force**: protect login, password reset and expensive endpoints (gateway, Bucket4j, or the platform's rate limiter).

## 7. Actuator and operational exposure

- Expose only what you need over HTTP: typically `health`, `info`, `prometheus`/`metrics`. `management.endpoints.web.exposure.include=*` on a public port is a data leak (`env`, `heapdump`, `threaddump`, `configprops`, `loggers` write access).
- Prefer a separate management port (`management.server.port`) not routed publicly, and secure non-health endpoints with their own filter chain.
- `management.endpoint.health.show-details=when-authorized`.
- `heapdump` and `threaddump` can contain secrets and personal data; never expose them publicly.

## 8. Headers, TLS, and misc hardening

- Spring Security's default headers (HSTS on HTTPS, X-Content-Type-Options, frame options, cache control) are good — don't disable them wholesale. Add a Content-Security-Policy for apps serving HTML.
- TLS: terminate at the platform or configure via SSL bundles (`spring.ssl.bundle.*`, Boot 3.1+), which also support certificate reloading. Never disable certificate validation in HTTP clients, even "temporarily".
- Behind a proxy/load balancer: set `server.forward-headers-strategy` so redirects and generated URLs use the original scheme/host — and only trust forwarded headers from your proxy.
- Session fixation protection and secure cookie flags are on by default for session apps; keep them.
- Limit request sizes (`spring.servlet.multipart.max-file-size`, `server.tomcat.max-swallow-size`, etc.) on upload endpoints.

## 9. Dependency hygiene

- Rely on the Spring Boot BOM for versions; don't pin individual Spring/Jackson/Hibernate versions unless patching a CVE, and remove the override after upgrading Boot.
- Keep Boot on a supported line and on the latest patch release; patch releases carry security fixes.
- Run a dependency vulnerability scan in CI (OWASP Dependency-Check, the build platform's scanner, or similar) as part of the verification loop.
