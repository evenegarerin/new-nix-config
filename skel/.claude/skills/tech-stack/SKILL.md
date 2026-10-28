---
name: tech-stack
description: >
  Tech-Stack-Guide für Projekte mit Kotlin/Spring-Boot-Backend und
  React-Frontend. Führt durch alle Stack-Entscheidungen (Projekttyp, Sub-Track
  MVC oder WebFlux, Datenbank, Auth, Domain Events, Modell-Strategie,
  Frontend-Features, Infrastruktur) und scaffoldet danach das Gradle-Monorepo
  mit korrekter Struktur, Dependencies, Guardrails und Rules.
  Verwende diesen Skill IMMER wenn: ein neues Spring-Boot- oder React-Projekt
  aufgesetzt werden soll, "neues Projekt", "Projekt aufsetzen", "scaffold",
  "init project", "Spring Boot Projekt", "Kotlin Backend", "React Frontend",
  "MVC oder WebFlux?", "JPA oder R2DBC?", "Tech-Stack", "Architektur-Entscheidung",
  oder wenn Stack-Fragen für ein Spring-Boot/React-Projekt beantwortet werden müssen —
  auch wenn der Benutzer den Stack nicht explizit nennt.
---

# Stack: Kotlin Spring Boot + React

Interaktiver Guide für Stack-Entscheidungen und Scaffolding. Dieser Skill kennt
**genau einen Stack**: Kotlin/Spring Boot im Backend, React (Vite + MUI +
TanStack) im Frontend. Andere Backends (Hono, Rust, Node) sind hier nicht
vorgesehen — wünscht der Benutzer einen anderen Stack, weise darauf hin und
nutze ggf. einen anderen Skill.

## Workflow

Führe den Benutzer in Reihenfolge durch diese Phasen. Stelle pro Entscheidung
eine Frage (Tool für Rückfragen nutzen, falls verfügbar) und gib jeweils eine
Empfehlung mit Begründung aus der Projektbeschreibung.

### Phase 1: Projekt-Grunddaten

1. **Projektname** (kebab-case, z.B. `invoice-service`, `fleet-dashboard`)
2. **Basis-Package** (Reverse-Domain, z.B. `com.example`) — im Folgenden `{basePackage}`
3. **Kurzbeschreibung** (1 Satz)
4. **Projekttyp**:

| Typ | Ergebnis |
|-----|----------|
| **Full-Stack** (Standard) | Spring Boot Backend + React SPA, ein Gradle-Monorepo, ein Deployment |
| **Backend-only** | Spring Boot REST-API ohne Frontend-Modul |
| **Frontend-only** | React SPA gegen ein bestehendes Spring-Boot-Backend (Client via Hey-API aus dessen OpenAPI-Spec) |

Bei Frontend-only: Phasen 2–4 überspringen, aber nach der URL der OpenAPI-Spec
des Ziel-Backends fragen.

### Phase 2: Backend-Konfiguration

**Sub-Track:**

| Sub-Track | Wann verwenden |
|-----------|----------------|
| **MVC + JPA + Virtual Threads** (Standard) | Klassische synchrone APIs, komplexes ORM, Hibernate, einfache DB-Queries |
| **WebFlux + R2DBC + Coroutines** | Hohe Concurrency, Non-Blocking I/O, Streaming-Responses, viele SSE-Verbindungen |

**Empfehlung:** MVC. Virtual Threads decken die meisten Concurrency-Anforderungen
ab; WebFlux nur bei echtem Streaming- oder Non-Blocking-Bedarf.

Die Wahl steuert:
- Core-Dependencies (`web` vs. `webflux`, `data-jpa` vs. `data-r2dbc`)
- Flyway-Konfiguration (automatisch vs. separate JDBC-URL bei R2DBC)
- OpenAPI-Starter (`webmvc-ui` vs. `webflux-ui`)
- Controller-Style (`@RestController` vs. Coroutine-Handler / `RouterFunction`)
- SPA-Serving (`WebMvcConfigurer` vs. `RouterFunction`)
- Repositories (`JpaRepository` vs. `CoroutineCrudRepository`)
- Kotlin-Patterns (blocking vs. `suspend fun` / `Flow<T>`)

**JSON-Serialisierung** (nur fragen, wenn relevant):

| Option | Wann |
|--------|------|
| **Jackson 3** (Standard) | Spring-Boot-Default, volle Integration |
| **kotlinx.serialization** | Kotlin-Multiplatform, kein Reflection gewünscht |

**Domain Events** (explizit fragen — Opt-in, kein Default):

| Option | Wann |
|--------|------|
| **Keine Events** (Standard) | Module kommunizieren über öffentliche Service-Calls. `spring-modulith-starter-core` genügt. |
| **Domain Events aktivieren** | Modulübergreifende Seiteneffekte (Mail, Read-Model, Audit), viele Module, drohende Zyklen. Zieht `spring-modulith-starter-jdbc`, `event_publication`-Flyway-Migration und Event-Config in `application.yml` nach sich. |

**Empfehlung:** Ohne Events starten (YAGNI). Nachrüsten ist jederzeit möglich.

**Modell-Strategie** (explizit fragen):

| Option | Wann |
|--------|------|
| **Zwei Modelle** (Standard) | DTO + JPA-Entity; Entity ist Domain-Objekt (keine anämischen Entities). Passt für Business-CRUD. |
| **Drei Modelle** | Reiche Geschäftslogik, echte Persistenz-Unabhängigkeit (Hexagonal): reines Kotlin-Domain-Modell + Persistence-Entity + DTO, Repository-Port/-Adapter, doppeltes Mapping. |

Eine Strategie pro Projekt, nicht mischen. Entscheidung + Begründung landen in
`docs/architecture/zielbild-schichten-und-events.md`.

### Phase 3: Datenbank

| Option | Wann |
|--------|------|
| **PostgreSQL** (Standard) | Mehrbenutzer, komplexe Queries, Production |
| **PostgreSQL + TimescaleDB** | Zeitreihen, Analytics, Metriken |

Migrations immer via Flyway. Tests mit Testcontainers.

### Phase 4: Auth

| Option | Wann |
|--------|------|
| **Keycloak/OIDC** (Standard) | SSO, RBAC mit Rollen, bestehende Keycloak-Instanz. Backend als Resource Server (JWT), Frontend via OIDC-Client. |
| **Keine Auth** | Interne Tools ohne Benutzerbezug |

### Phase 5: Frontend-Features

Nur bei Full-Stack oder Frontend-only. Mehrfachauswahl:

| Feature | Library |
|---------|---------|
| Charts/Visualisierung | D3.js (custom SVG) oder Recharts (deklarativ) |
| Komplexe Formulare | TanStack Form + `useAppForm` + `withFieldGroup` |
| i18n | i18next + react-i18next |
| PDF | react-pdf (Anzeige), Typst im Backend (Erzeugung) |
| DataGrid/Tabellen | MUI X DataGrid |
| File Upload | react-dropzone |
| Real-Time Updates | SSE (`useSSE`-Hook) |
| Notifications | Sonner |

**PWA ist kein Feature, sondern gesetzt.** Jedes Frontend wird als Progressive
Web App gebaut (`vite-plugin-pwa`, Manifest, Service Worker, Offline-Fallback) —
siehe Stack-Standards → PWA. Nicht
danach fragen, nur die PWA-Metadaten erheben: App-Name, Kurzname (≤ 12 Zeichen),
`theme_color`, `background_color`.

### Phase 6: Infrastruktur

1. **Docker**: Ja (Standard) | Nein
2. **GitLab CI**: Ja (Standard) | Nein
3. **Kubernetes-Manifeste**: Nein (Standard) — Deployment-Manifeste gehören in ein separates GitOps-/Deployment-Repo, nicht ins Scaffolding
4. **Container-Registry**: Host der Registry (z.B. `registry.example.com`) — im Folgenden `{registry}`
5. **Secrets**: Welche Zugangsdaten (DB, Keycloak-Client-Secret, S3, SMTP, Fremd-APIs) werden gebraucht?

Der Weg ist gesetzt — OpenBao → `.envrc` → Umgebungsvariablen (Skill `secrets`).
Gefragt wird nur, *welche* Secrets es gibt und wie die Variablen heißen.

**Guardrails (Pflicht, nicht verhandelbar):** Rules in `.claude/rules/` sind nur
Doku; ohne maschinelle Erzwingung erodiert die Architektur. Generiere daher immer:

1. **CI-`check`-Stage vor dem Build** — Tests, Lint, Typecheck laufen in der Pipeline. Kein Pfad, auf dem Tests per `-x test` komplett umgangen werden.
2. **`justfile`** als Einstiegspunkt (`just check` / `test` / `lint` / `generate-api` / `dev`).
3. **Frontend-Lint im Gradle-Build-Graph** — `check.dependsOn(pnpmLint)`, damit ein Befehl alles prüft.
4. **ArchUnit- oder Konsist-Test** neben Modulith-`verify()` — deckt ab, was `verify()` nicht kann: `@Entity` außerhalb `internal/`, Controller mit Repository/`JdbcTemplate`, passives `common`.
5. **OpenAPI-Drift-Check** (Full-Stack) — CI-Job generiert die Spec neu und prüft `git diff --exit-code`.

### Phase 7: Zusammenfassung

Zeige alle Entscheidungen als kompakte Tabelle. **Warte auf Bestätigung**, bevor
das Scaffolding beginnt.

### Phase 8: Scaffolding

#### Versionsermittlung (Pflicht, vor jedem Schreiben)

Verlasse dich **nie** auf trainiertes Wissen für Versionsnummern — es ist beim
Scaffolding praktisch immer veraltet.

- **npm** (React, Vite, MUI, TanStack, Hey-API, …): `package.json`
  ohne Dependencies anlegen, dann `pnpm add <pkg> …` bzw. `pnpm add -D <pkg> …`.
  pnpm schreibt die aktuelle Version selbst. Bei privaten Paketen aus einer eigenen Registry muss die `.npmrc` vorher liegen.
- **Gradle/Maven** (Spring Boot, Spring Modulith, Kotlin, springdoc-openapi, MockK,
  Testcontainers, ArchUnit, node-gradle-Plugin): live auf der offiziellen
  Release-Seite oder Maven Central nachschlagen, erst dann in `build.gradle.kts` /
  Version Catalog eintragen.
- **Tooling** (Node.js LTS, pnpm, Gradle Wrapper, JDK): offizielle Release-Seite
  prüfen; pnpm via `corepack use pnpm@latest`.

Lookups parallel ausführen. Bei fehlendem Netz: **keine Versionen raten.** Frag
den Benutzer nach den Versionen oder lass die betroffenen Einträge offen (`TODO:
Version prüfen`) und sag ausdrücklich, welche Teile deshalb unvollständig sind.
Danach eine Tabelle der tatsächlich gesetzten Versionen zeigen ("Stand: {Datum}").

#### Scope

Das Scaffolding erstellt **nur**:
- Gradle-Monorepo mit Build-Konfiguration
- Leere Package-Struktur im Core-Modul (nur `.gitkeep`)
- Application Entry Point (`@SpringBootApplication` + `@Modulithic`)
- `SuccessResponse<T>`-Wrapper
- `ModulithArchitectureTest` + ArchUnit/Konsist-Companion-Test
- Frontend-Skeleton (Vite, Theme, Router, Hey-API-Config, Lint-Setup, PWA-Setup: Manifest, Service Worker, Icons, Offline-Fallback)
- Infrastruktur (Dockerfile, docker-compose, `.gitlab-ci.yml` mit `check`-Stage, `justfile`, `.env.example`)
- `.envrc` (OpenBao-Secrets als Umgebungsvariablen)
- `CLAUDE.md` + `.claude/rules/`
- `docs/architecture/zielbild-schichten-und-events.md`
- Event Publication Registry nur, wenn Events gewählt wurden

Es erstellt **keine** Entities, DTOs, Services, Controller, Migrations oder
Beispiel-Module — die entstehen im Feature-Workflow.

#### Struktur Full-Stack

```
{project-name}/
├── {name}-api/               # Pure Kotlin: DTOs, Enums, Interfaces (java-library, spring-frei)
├── {name}-core/              # Spring Boot Library: Domain-Module (Modulith)
├── {name}-app/               # Entry Point, application.yml, Flyway, Framework-Wiring
├── {name}-frontend/          # React SPA als Gradle-Modul (node-gradle Plugin)
│   ├── build.gradle.kts      # pnpmBuild, pnpmLint, bootJar disabled
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts        # Proxy auf Backend im Dev-Modus
│   ├── openapi-ts.config.ts  # Hey-API
│   └── src/
│       ├── main.tsx
│       ├── routes/
│       ├── api-client/       # Hey-API generiert — nie von Hand ändern
│       ├── hooks/            # Data-Fetching-Hooks (TanStack Query)
│       ├── components/
│       ├── theme/            # MUI-Theme (createTheme)
│       └── ui/               # Projektweite Basis-Komponenten
│   └── public/
│       ├── icons/            # PWA-Icons 192px + 512px (+ maskable)
│       └── offline.html      # Offline-Fallback
├── build.gradle.kts
├── settings.gradle.kts       # include("{name}-api", "{name}-core", "{name}-frontend", "{name}-app")
├── gradle/wrapper/
├── gradle.properties
├── docker-compose.yaml
├── Dockerfile
├── .gitlab-ci.yml
├── .env.example
├── .envrc
├── justfile
└── CLAUDE.md
```

**Wichtig:**
- Das Frontend-Modul ist **keine** `implementation`-Dependency des App-Moduls — sonst baut jeder `bootRun` das Frontend.
- Dev: `bootRun` und `pnpm dev` laufen getrennt, Vite proxyt `/api` aufs Backend.
- Docker: Frontend separat bauen, Assets ins Release-Image kopieren; Spring Boot liefert sie via `spring.web.resources.static-locations` aus (Single Deployment).

#### Struktur Backend-only

Wie oben ohne `{name}-frontend/`; `settings.gradle.kts`:
```kotlin
include("{name}-api", "{name}-core", "{name}-app")
```

Dockerfile (kein Node.js nötig):
```dockerfile
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY gradlew build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle
COPY {name}-api {name}-api
COPY {name}-core {name}-core
COPY {name}-app {name}-app
# Tests laufen in der CI-check-Stage vor diesem Build
RUN ./gradlew :{name}-app:bootJar -x test --no-daemon

FROM eclipse-temurin:21-jre AS release
WORKDIR /app
RUN groupadd -g 1001 appuser && useradd -u 1001 -g appuser appuser
COPY --from=build /app/{name}-app/build/libs/*.jar app.jar
USER appuser
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:4000/actuator/health || exit 1
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

#### Struktur Frontend-only

Eigenständiges pnpm-Projekt mit demselben `src/`-Layout wie oben, `openapi-ts.config.ts`
zeigt auf die Spec des bestehenden Backends. Dockerfile: Node-Build + statisches
Serving (z.B. nginx, non-root).

#### Core-Modul: Package-Regeln

- Im Scaffolding nur `src/main/kotlin/{basePackagePath}/{projectname}/.gitkeep` — **keine** leeren `api/`, `domain/`, `internal/`.
- **Keine** `ModuleMetadata.kt`, solange es kein konkretes Modul gibt. `@PackageInfo` + `@NamedInterface` werden pro Modul angelegt.
- **Kein** `src/main/java`, keine `package-info.java` — Kotlin-only.

#### Reihenfolge

1. Root-Konfiguration (`build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, Wrapper)
2. API-Modul (reines Kotlin; nur `jakarta.validation-api` + `swagger-annotations-jakarta`)
3. Core-Modul (Basis-Package mit `.gitkeep`)
4. App-Modul (`@Modulithic`-Application, `application.yml`, `db/migration/`, `ModulithArchitectureTest`, ArchUnit-Test)
5. Frontend-Modul (nur Full-Stack): `build.gradle.kts`, `package.json` ohne Deps, dann `pnpm add …`
6. Infrastruktur (Docker, CI, docker-compose, justfile, `.envrc`)
7. `CLAUDE.md`
8. `.claude/rules/`
9. `docs/architecture/zielbild-schichten-und-events.md`

#### CLAUDE.md

Muss enthalten: Repository Overview, Essential Commands (`just …`), Architecture
(Module, Schichten), Key Conventions (inkl. Code-Sprache Englisch), DOs/DON'Ts,
Troubleshooting.

#### `.claude/rules/`

Schreibe die Rules selbst aus den Stack-Standards weiter unten — es gibt keine
Template-Dateien, die du kopieren könntest. Pro Rule gilt:

- Eine Datei pro Thema, 20–60 Zeilen. Kurz und konkret, keine Lehrbuchtexte.
- Frontmatter: `description:` (ein Satz) und bei dateispezifischen Rules `globs:`
  (z.B. `**/*.tsx` für Frontend-Rules, `**/*.kt` für Kotlin-Rules).
- DO/DON'T mit je einem Codebeispiel aus *diesem* Projekt (echte Package- und
  Modulnamen, keine Platzhalter).
- Nur Kapitel schreiben, die auf die getroffenen Entscheidungen zutreffen —
  ohne gewählte Domain Events kein Event-Kapitel, ohne Frontend keine
  Frontend-Rules.

**Backend:**
- `clean-architecture.md` — Abhängigkeitsregel, Schichten, Modulgrenzen, Modell-Strategie
- `solid-principles.md`
- `dry-principles.md` — inkl. Schema-SSoT-Kette (s.u.); Abstraktion erst ab 3 Vorkommen
- `kiss-yagni.md`
- `naming-language.md` — Identifier Englisch
- `secrets-handling.md`
- `modulith-structure.md` — Package-Layout, Sichtbarkeit, `@NamedInterface`, Schichtinvarianten; Event-Kapitel nur bei gewählten Events
- `kotlin-standards.md` — Naming, Suffixe, Idiome, Testing (MockK)
- `spring-boot-4-pitfalls.md` — veraltete SB3-Starter, Jackson 2 statt 3, `@MockBean`, `RestTemplate`, Actuator `enabled`→`access`

**Frontend** (Full-Stack/Frontend-only):
- `react-code-standards.md` — Components, Props, Hooks; Data-Fetching-Hook-Schicht Pflicht (kein inline `useQuery`/`useMutation` in Routen/Komponenten)
- `mui-standards.md` — Theme, `sx` statt System-Props, Grid `size`, Accessibility
- `lint-setup.md` — type-aware ESLint (`recommendedTypeChecked`), geteiltes Paket `@{project}/eslint-config` (Base + React), `--max-warnings 0`
- `pwa.md` — Manifest-Pflichtfelder, Service-Worker-Strategie, Offline-Fallback, Lighthouse-Check vor Release

## Stack-Standards (gelten immer)

### Schema Single Source of Truth

Jedes Schema-Wissen hat genau eine Quelle; alles andere wird generiert:

| Schicht | Quelle |
|---------|--------|
| SSoT | Kotlin-DTOs im `{name}-api`-Modul + Bean Validation (`@field:…`) |
| Validierung | Bean Validation am DTO |
| API-Doku | springdoc → OpenAPI-Spec |
| Frontend-Typen + Client | Hey-API-Codegen aus der Spec |

Frontend-Typen werden **nie** von Hand geschrieben. Drift wird in CI geprüft.

### Kotlin / Spring Boot

- Aktuelles Spring Boot 4, Java 21 Toolchain, Kotlin (Versionen live ermitteln)
- Spring Modulith; `ModulithArchitectureTest` + ArchUnit-Companion dürfen nie gelöscht werden
- Package: `{basePackage}.{projectname}.{module}.{layer}`
  - `api/` — public: Controller, Service (`@NamedInterface` Pflicht)
  - `domain/` — public: geteilte Enums, optionale Events (`@NamedInterface` Pflicht)
  - `internal/` — Entities, Repositories, Mapper
- Service-Signaturen: DTOs/Enums/IDs rein und raus, nie Entities
- Modulfremde Referenzen als `UUID`, keine JPA-Relationen über Modulgrenzen, kein Raw-SQL auf fremde Tabellen
- `{name}-api` spring-frei; Framework-Wiring nur in `{name}-app`, kein `config`-Package in `-core`
- `SuccessResponse<T>` für alle Controller-Responses
- MockK (nicht Mockito), Testcontainers für DB-Tests
- MVC: Virtual Threads, blocking. WebFlux: `suspend fun`, `Flow<T>`, R2DBC

### React / Frontend

- Vite, TypeScript `strict: true`, `verbatimModuleSyntax: true`, `moduleResolution: "bundler"`
- `"type": "module"`, `@`-Alias → `./src/`
- Named function exports (`export function Component()`), keine Arrow-Components, keine Default-Exports
- Props als `interface`
- MUI mit `sx` — keine CSS-Dateien, kein Tailwind
- Ein zentrales MUI-Theme in `src/theme/`; wiederverwendbare Basis-Komponenten in `src/ui/`
- TanStack Router, TanStack Query für Server State (kein Redux; Zustand nur für spezifischen Client State)
- Hey-API-generierter Client, gekapselt in Data-Fetching-Hooks

### Code-Sprache

Alle Identifier Englisch (Variablen, Klassen, Packages, Dateien, DB-Tabellen/Spalten,
Routen, Config-Keys). Deutsch nur als Wert: UI-Texte, Fehlermeldungen für Nutzer,
Kommentare, Doku. Keine Umlaute/Transliterationen in Identifiern, kein Denglisch.
Ausnahmen (mit Kommentar): rechtliche Begriffe ohne Pendant, Normformate (DATEV,
XRechnung, ZUGFeRD), Fremdschemata (einmal im Adapter übersetzt), Eigennamen.

### Secrets: OpenBao + `.envrc`

Quelle der Wahrheit ist OpenBao. `.envrc` (direnv) holt die Werte und exportiert
sie als Umgebungsvariablen; die Anwendung liest ausschließlich Umgebungsvariablen
und kennt OpenBao nicht. Details im Skill `secrets`.

| | Ort | Beispiele |
|---|---|---|
| Nicht geheim | `.env.example` / Env-Variablen | `SERVER_PORT`, `SPRING_PROFILES_ACTIVE`, Keycloak-Issuer/JWKS, S3-Endpoint/Bucket |
| Geheim | OpenBao → `.envrc` → Env-Variable | DB-Passwort/URL, Keycloak-Client-Secret, S3-Keys, SMTP, API-Tokens |

Kein Secret in `.env.example`, auch nicht als Platzhalter. Keine Vault-/OpenBao-
Clients im Anwendungscode. Spring liest die Variablen über Placeholder in
`application.yml` (`${SPRING_DATASOURCE_PASSWORD}`) — ohne Default-Wert, damit der
Start bei fehlendem Secret laut scheitert.

```bash
# .envrc

# --- Entwicklung: OpenBao gemockt mit offensichtlich falschen Werten ---
export SPRING_DATASOURCE_PASSWORD="dev-fake-password"
export KEYCLOAK_CLIENT_SECRET="dev-fake-client-secret"

# --- Echt: aus OpenBao holen ---
# export SPRING_DATASOURCE_PASSWORD="$(bao kv get -mount=secret -field=password {project}/database)"
# export KEYCLOAK_CLIENT_SECRET="$(bao kv get -mount=secret -field=client_secret {project}/keycloak)"
```

Fake-Werte müssen als solche erkennbar sein (`dev-`/`fake-`-Präfix). Nach jeder
Änderung an `.envrc`: `direnv allow`. Welche OpenBao-Pfade für Staging/Production
angelegt werden müssen, dem Benutzer sagen — nicht selbst in OpenBao schreiben.

### Infrastruktur

- Docker Multi-Stage → Container-Registry, Image `{registry}/{project}/app`
- CI: `check`-Stage → Image-Build → Push; eine vorhandene zentrale Build-Komponente der Organisation hat Vorrang vor handgeschriebenem `docker build`/`push`
- Tags: Default-Branch → `:staging`, Git-Tag `app-X.Y.Z` → `:X.Y.Z`
- Registry-Zugang als geschützte CI-Variablen `REGISTRY_USERNAME`/`REGISTRY_PASSWORD` (nicht expandieren lassen, falls sie `$` enthalten)
- Pull-Credentials im Cluster aus dem Secret-Store, nie im Repo
- Non-root (UID 1001), Healthcheck `/actuator/health`
- JVM: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`
- 12-Factor: Konfiguration über Env-Variablen
- Full-Stack: Spring Boot liefert das Frontend als Static Files aus

## Referenzen

Bei Bedarf lesen:
- `references/spring-boot-track.md` — Gradle-Multi-Modul, Frontend-Trennung, Hey-API, ArchUnit-Test, Event-Setup
- `references/frontend-patterns.md` — Vite, Theme, Router, ESLint-Config-Paket
- `references/infrastructure.md` — Dockerfile, CI mit `check`-Stage, justfile, secretspec-Templates
- `references/rules.md` — Templates für `.claude/rules/`
- `references/versions.md` — nur Fallback-Baseline
