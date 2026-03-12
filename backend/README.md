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

## Important Environment Settings

The backend reads settings from the root `.env` file with the `BACKEND_` prefix.

Commonly used values:

- `BACKEND_DATABASE_URL`: async database URL for the running app
- `BACKEND_ALEMBIC_DATABASE_URL`: optional sync URL override for Alembic
- `BACKEND_AUTH_SECRET_KEY`: signing secret for bearer tokens; use a 32+ character value outside local development
- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS`: access-token lifetime in seconds
- `BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS`: password-reset token lifetime in seconds
- `BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS`: email-verification token lifetime in seconds
- `BACKEND_DOCS_ENABLED`: enable or disable `/docs`, `/redoc`, and OpenAPI JSON
- `BACKEND_CORS_ALLOWED_ORIGINS`: explicit extra CORS origins when localhost defaults are not enough

Localhost origins are already allowed by default for web demos. The app also logs a reminder at startup if the default development auth secret is still in use.

## Current Auth Behavior

The backend now uses real auth for normal MVP use:

- `POST /api/v1/auth/signup` creates a user, hashes the password, and returns a bearer token
- `POST /api/v1/auth/login` verifies credentials and returns a bearer token
- `GET /api/v1/auth/session` restores the current authenticated session
- authenticated feature endpoints resolve the user from `Authorization: Bearer <token>`
- `POST /api/v1/auth/password-reset/request` creates a password-reset challenge without disclosing whether the account exists
- `POST /api/v1/auth/password-reset/confirm` validates a one-time token, rotates the account token version, and returns a new bearer token
- `POST /api/v1/auth/email-verification/request` creates an email-verification challenge for the signed-in user
- `POST /api/v1/auth/email-verification/confirm` marks the email as verified when the one-time token is valid

Local-only behavior:

- password reset and email verification preview tokens are only returned in `development`, `local`, and `test`
- token-version checks provide low-risk groundwork for future session invalidation and refresh-token work
- the current repo does not send real email yet

Still intentionally deferred:

- refresh tokens and full server-side session revocation
- outbound email delivery and email verification UI enforcement
- social auth

## Current Route Surface

- `GET /api/v1/health`
- `GET /api/v1/system/foundation`
- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/session`
- `POST /api/v1/auth/password-reset/request`
- `POST /api/v1/auth/password-reset/confirm`
- `POST /api/v1/auth/email-verification/request`
- `POST /api/v1/auth/email-verification/confirm`
- `GET /api/v1/users/me`
- `PATCH /api/v1/users/me`
- `GET /api/v1/goals/current`
- `PUT /api/v1/goals/current`
- `GET /api/v1/preferences`
- `PUT /api/v1/preferences`
- `GET /api/v1/foods/search?q=`
- `GET /api/v1/foods/{food_id}`
- `GET /api/v1/meals?date=YYYY-MM-DD`
- `POST /api/v1/meals/entries`
- `PATCH /api/v1/meals/entries/{entry_id}`
- `DELETE /api/v1/meals/entries/{entry_id}`
- `GET /api/v1/nutrition/overview?range=day&date=YYYY-MM-DD`
- `GET /api/v1/nutrition/macro/{macro_type}?range=day&date=YYYY-MM-DD`
- `GET /api/v1/progress/overview`
- `GET /api/v1/progress/weight`
- `POST /api/v1/progress/weight`
- `GET /api/v1/progress/measurements`
- `POST /api/v1/progress/measurements`

## Demo Data Notes

Food search and food detail use a small seeded demo dataset when the foods table is empty. That keeps local demos predictable without introducing a large fake dataset.

Good demo search terms include:

- `yogurt`
- `chicken`
- `rice`
- `banana`
- `oats`
- `salmon`

## Local Verification

With the backend virtual environment active:

```powershell
pytest -q
```

Focused smoke checks that are especially useful before demos:

- auth signup/login/session restore
- forgot-password request and reset flow
- Today read contract
- meal search and add flow
- Nutrition overview
- Progress create flows
- More profile/goals/preferences endpoints

## Known Limits

- this backend is ready for local demos and auth hardening work, not full production deployment
- release packaging, hosted deployment, observability, and stronger secret management are still future work
- refresh-token rotation, email delivery, and full session-management infrastructure are still future work
