# backend

FastAPI backend for `fitness-app`.

## Current State

The backend currently provides:

- real signup, login, bearer token issuing, and current-session restore
- bearer-token current-user resolution for authenticated routes
- password reset challenge and confirmation endpoints
- email verification challenge foundations for future frontend wiring
- users, goals, preferences, foods, meals, nutrition, progress, health, and system endpoints
- PostgreSQL persistence through SQLAlchemy
- Alembic migrations
- a small seeded demo food dataset for local demos and smoke passes
- a Dockerfile and migration-aware entrypoint suitable for simple staging deployment

## Local Quick Start

### 1. Create the root `.env`

From the repository root:

```powershell
Copy-Item .env.example .env
```

### 2. Start PostgreSQL

```powershell
docker compose up -d postgres
docker compose ps
```

### 3. Run the backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .[dev]
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Useful local URLs:

- API docs: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- API prefix: `http://localhost:8000/api/v1`

## Simple Container Run

The backend now includes:

- `Dockerfile`
- `entrypoint.sh`

Build and run locally or on a staging instance with:

```powershell
cd backend
docker build -t fitness-app-backend .
docker run --rm --env-file ..\.env -p 8000:8000 fitness-app-backend
```

If `BACKEND_RUN_MIGRATIONS=1`, the entrypoint runs `alembic upgrade head` before starting Uvicorn.

## Important Environment Settings

The backend reads settings from the root `.env` file with the `BACKEND_` prefix.

Commonly used values:

- `BACKEND_ENVIRONMENT`: `development` locally; use `staging` or another non-local value for hosted environments
- `BACKEND_DATABASE_URL`: async database URL for the running app
- `BACKEND_ALEMBIC_DATABASE_URL`: sync URL override for Alembic
- `BACKEND_AUTH_SECRET_KEY`: signing secret for bearer tokens; use a 32+ character value outside local development
- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS`: access-token lifetime in seconds
- `BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS`: password-reset token lifetime in seconds
- `BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS`: email-verification token lifetime in seconds
- `BACKEND_DOCS_ENABLED`: enable or disable `/docs`, `/redoc`, and OpenAPI JSON
- `BACKEND_CORS_ALLOWED_ORIGINS`: explicit frontend origins for hosted environments
- `BACKEND_CORS_ALLOW_ORIGIN_REGEX`: optional preview-host regex for dynamic frontend preview URLs
- `BACKEND_RUN_MIGRATIONS`: container-start helper for `entrypoint.sh`

Localhost CORS defaults only auto-apply in local-style environments (`development`, `local`, `test`).

## Recommended AWS Staging Shape

For the current MVP, the simplest AWS staging deployment is:

- one Lightsail Linux instance serving the Flutter web build and reverse proxy
- this backend running in Docker on that same instance
- one Lightsail managed PostgreSQL database

See the root [DEPLOYMENT.md](../DEPLOYMENT.md) for the ordered AWS staging steps.

## Local Verification

With the backend virtual environment active:

```powershell
pytest -q
```

Focused smoke checks that are especially useful before demos or staging rollout:

- auth signup/login/session restore
- forgot-password request and reset flow
- Today read contract
- meal search and add flow
- Nutrition overview
- Progress create flows
- More profile/goals/preferences endpoints

## Known Limits

- this backend is ready for demos and a simple staging rollout, not full production operations
- release automation, observability, and secret-manager integration are still future work
- refresh-token rotation, email delivery, and full session-management infrastructure are still future work
