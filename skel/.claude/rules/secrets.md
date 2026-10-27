## Secrets

- Secrets are managed in OpenBao and loaded into environment variables via `.envrc`.
- Code reads secrets only from environment variables. Never hardcode, log, or commit secrets, and never access OpenBao from application code.
- In development, OpenBao may be mocked with obviously fake values hardcoded in `.envrc`.