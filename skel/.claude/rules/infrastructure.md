## Infrastructure
- Always run external services (databases, caches, queues, search engines, etc.) in Docker containers. Never install them directly on the host.
- Define them in `docker-compose.yml` at the project root, with pinned image versions.
- Start them with `docker compose up -d` and connect via the exposed ports.
- If a needed service isn't in the compose file yet, add it there instead of using a locally installed one.