# Compose patterns

## Contents
- Full annotated example
- Healthchecks for common services
- Dev / prod overlays
- `develop.watch`
- Extension fields and anchors
- Profiles
- Useful commands

## Full annotated example

```yaml
name: shop

x-hardening: &hardening          # extension field: must appear above `services:`
  init: true                       # reaps zombies, forwards signals
  read_only: true
  tmpfs: [/tmp]
  cap_drop: [ALL]
  security_opt: ["no-new-privileges:true"]
  pids_limit: 256
  logging:
    driver: local                  # rotated by default; json-file grows forever

services:
  api:
    <<: *hardening
    build:
      context: .
      target: runtime
    image: ghcr.io/acme/shop-api:${APP_TAG:-dev}
    ports:
      - "127.0.0.1:8000:8000"      # loopback: Docker bypasses ufw/firewalld
    environment:
      DB_HOST: db
      DB_NAME: shop
      DB_USER: shop
      DB_PASSWORD_FILE: /run/secrets/db_password
      API_KEY: ${API_KEY:?set API_KEY in .env}   # fail loudly if missing
    secrets: [db_password]
    depends_on:
      db:
        condition: service_healthy
        restart: true              # restart api if db is restarted
    networks: [frontend, backend]
    deploy:
      resources:
        limits: { cpus: "1.0", memory: 512M }
    restart: unless-stopped

  db:
    image: postgres:18-alpine
    environment:
      POSTGRES_DB: shop
      POSTGRES_USER: shop
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets: [db_password]
    volumes:
      - pgdata:/var/lib/postgresql   # postgres 18+ path; <=17 used /var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shop -d shop"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s
    networks: [backend]            # no published port: only reachable by services
    restart: unless-stopped

networks:
  frontend:
  backend:
    internal: true                 # no outbound internet from this network

volumes:
  pgdata:

secrets:
  db_password:
    file: ./secrets/db_password.txt   # gitignored
```

Things to notice:
- `deploy.resources.limits` is honored by `docker compose` (v2), not only Swarm.
- `internal: true` cuts the backend off from the internet — the api also joins `frontend` so it keeps egress.
- `read_only: true` breaks apps that write outside `/tmp`; add specific `tmpfs` or volumes rather than dropping `read_only`.
- `cap_drop: [ALL]` breaks images that start as root and drop privileges (official postgres, nginx non-unprivileged); harden your own services, test before hardening third-party ones.

## Healthchecks

Use tools the image actually ships. Set `start_period` generously for first-boot initialization.

| Service | `test` |
|---|---|
| Postgres | `["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]` |
| MySQL | `["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]` |
| MariaDB 10.4+ | `["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]` |
| Redis / Valkey | `["CMD", "redis-cli", "ping"]` (`valkey-cli` for valkey) |
| MongoDB | `["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]` |
| RabbitMQ | `["CMD", "rabbitmq-diagnostics", "-q", "ping"]` |

`$$` escapes `$` so the variable is expanded inside the container, not by compose.

Use `-h 127.0.0.1` (TCP) for MySQL: during first-boot init, MySQL/MariaDB run a temporary server on the socket only, so a socket-based ping (and the `ready for connections` log line, which is printed twice) reports ready while the seed import is still running.

## Dev / prod overlays

```
compose.yaml            # shared: services, networks, volumes
compose.override.yaml   # auto-loaded: dev bind mounts, debug ports, dev target
compose.prod.yaml       # explicit: docker compose -f compose.yaml -f compose.prod.yaml up -d
```

Check the merged result with `docker compose -f compose.yaml -f compose.prod.yaml config`. Lists like `ports` are appended when merged, not replaced — use `!reset []` or `!override` to replace them.

Anchors (`&x` / `*x`) are file-local: each overlay file needs its own.

## develop.watch (preferred dev loop)

```yaml
services:
  api:
    build: { context: ., target: dev }
    develop:
      watch:
        - action: sync
          path: ./src
          target: /app/src
        - action: rebuild
          path: package-lock.json
```

Run `docker compose watch` (or `up --watch`). Unlike bind-mounting the repo, this doesn't hide the container's `node_modules`, works well on macOS/Windows file systems, and doesn't produce root-owned files on the host.

If you do bind-mount, protect installed deps with an anonymous volume (`- /app/node_modules`) and run the container as the host user (`user: "${UID}:${GID}"`, export the vars first) so generated files aren't root-owned.

## Shared image references

```yaml
x-app-image: &app-image ghcr.io/acme/shop:${APP_TAG:-1.4.2}
services:
  web:    { image: *app-image, command: ["web"] }
  worker: { image: *app-image, command: ["worker"] }
```

Define once so web and worker can never drift to different versions.

## Profiles

```yaml
  adminer:
    image: adminer:5
    profiles: [debug]
    ports: ["127.0.0.1:8080:8080"]
```

`docker compose --profile debug up`. Shutdown gotcha: `docker compose down` and `up --remove-orphans` ignore containers belonging to profiles that aren't active — use `docker compose --profile '*' down` to stop everything.

## Useful commands

```bash
docker compose config -q                 # validate (needs .env present for :? vars)
docker compose up -d --wait              # returns when healthchecks pass; great in CI
docker compose up -d --build api         # rebuild + restart one service
docker compose logs -f --tail=100 api
docker compose exec api sh               # into running container
docker compose run --rm api npm test     # one-off container
docker compose ps --format json
docker compose down                      # keeps volumes
docker compose down -v                   # DELETES named volumes — ask first
```
