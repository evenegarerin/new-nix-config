---
name: secrets
description: How secrets are managed in this project (OpenBao + .envrc/direnv + environment variables). Use this skill whenever adding, renaming, removing, or reading a secret, password, API key, token, certificate or credentialed connection string; when editing .envrc; when configuring a new service or integration that needs credentials; or when debugging missing or wrong environment variables.
---

# Secrets

## Overview

- **Source of truth:** OpenBao (KV secrets engine).
- **Delivery:** `.envrc` (loaded by direnv) fetches secrets and exports them as environment variables.
- **Consumption:** application code reads secrets only from environment variables.

The app never knows OpenBao exists. Swapping real secrets for fake ones only ever touches `.envrc`.

## Reading secrets in code

- Read each secret from a clearly named, uppercase environment variable (e.g. `DATABASE_PASSWORD`, `STRIPE_API_KEY`).
- Validate required secrets at startup and fail fast with an error naming the missing variable, never its value.
- Never provide a default or fallback secret value in code.
- Never log, print, or include secret values in error messages, exceptions, or test snapshots.
- Never import an OpenBao/Vault client in application code.

## Adding a new secret

1. Choose an environment variable name and read it in code as described above.
2. Add a fake value for it to the development section of `.envrc`.
3. Add the commented OpenBao fetch line next to it, with the real path and field.
4. Tell the user which OpenBao path and field must be created for real environments. Do not create or modify secrets in OpenBao yourself unless explicitly asked.
5. Run `direnv allow` (or ask the user to) so the updated `.envrc` is loaded.

Removing or renaming a secret follows the same steps in reverse: update code, `.envrc`, and tell the user which OpenBao entry is now obsolete.

## `.envrc` structure

```bash
# --- Development: OpenBao mocked with fake values ---
export DATABASE_PASSWORD="dev-fake-password"
export STRIPE_API_KEY="fake-stripe-key"

# --- Real: fetch from OpenBao ---
# export DATABASE_PASSWORD="$(bao kv get -mount=secret -field=password myapp/database)"
# export STRIPE_API_KEY="$(bao kv get -mount=secret -field=api_key myapp/stripe)"
```

Fetching real values requires the `bao` CLI and an authenticated session (`BAO_ADDR` and a valid token, e.g. via `bao login`).

## Fake values in development

- Fake values must be obviously fake (prefix with `dev-` or `fake-`) so they can never be mistaken for real ones.
- Never copy a real secret into `.envrc` as a plain value, not even temporarily.
- If a fake value must match a format to work (e.g. a JWT signing key length, a URL), generate a valid but fake one.
- Tests use the same environment variables; never hardcode secrets inside test files.

## Troubleshooting

- **Variable is empty or missing:** check that direnv is active and `.envrc` is allowed (`direnv allow`), then check the variable exists in `.envrc`.
- **OpenBao fetch fails:** check `BAO_ADDR`, that the token is valid (`bao token lookup`), and that the path and field exist (`bao kv get -mount=secret myapp/<name>`). Never echo the fetched value while debugging; check only whether it is set (`[ -n "$VAR" ] && echo set`).