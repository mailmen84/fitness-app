# fitness-app

`fitness-app` is a cross-platform nutrition and fitness tracking monorepo with a Flutter client and a FastAPI backend. The repository now has an authenticated working MVP across Today, Add, Nutrition, Progress, and More/settings.

## Non-Negotiable Repository Rule

All work must stay inside the existing repository root:

- `C:\New folder\fitness-app`

Do not create a new root folder, do not create a nested `fitness-app` folder, and do not move work into a second top-level project directory.

## Current Phase

Current phase: deployment and demo readiness.

This phase focuses on making the authenticated MVP easier to run, demonstrate, verify, and maintain without adding major new product features.

## Current MVP Scope

Working today:

- real signup and login with bearer-token session restore
- onboarding flow after signup
- Today dashboard with date selection and meal sections
- Add flow with quick add, food search, food detail, and meal detail
- Nutrition overview with day, week, and month ranges
- Progress overview, weight logging, and measurement logging
- More/Profile home plus profile, goals, and preferences settings
- seeded demo foods for search and meal logging demos

Still intentionally not product-complete:

- refresh tokens or server-side session revocation
- email verification, password reset, or social auth
- barcode scanning, recipes, or saved multi-food meal templates
- advanced nutrition analytics or chart-heavy progress coaching
- release packaging, hosted deployment, and production hardening

## Tech Stack

- Frontend: Flutter, Material 3, Riverpod, go_router, `http`
- Backend: FastAPI, Pydantic, SQLAlchemy, Alembic
- Database: PostgreSQL
- Local infrastructure: Docker Compose for PostgreSQL
- Testing: Flutter widget tests, FastAPI TestClient tests

## Repository Structure

```text
fitness-app/
  apps/
    mobile_web_flutter/
      lib/
      test/
  backend/
    app/
    alembic/
    tests/
  .env.example
  docker-compose.yml
  README.md
  CODEX_CONTEXT.md
  NEXT_TASK.md
```

## Local Quick Start

### 1. Create local config

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

Local backend URLs:

- API root: `http://localhost:8000/api/v1`
- Swagger docs: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### 4. Run the Flutter app

If the platform runners have not been generated yet, hydrate them first:

```powershell
cd apps\mobile_web_flutter
flutter create . --platforms=android,ios,web,windows,linux,macos
```

Then install packages, run tests, and start the web app:

```powershell
cd apps\mobile_web_flutter
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

`API_BASE_URL` can be either:

- a backend origin, for example `http://localhost:8000`
- or the full API prefix, for example `http://localhost:8000/api/v1`

The Flutter client now tolerates both forms.

## Config Notes

### Backend config

The root `.env` file configures the backend. The most relevant settings for local work are:

- `BACKEND_DATABASE_URL`: async SQLAlchemy database URL used by the app
- `BACKEND_ALEMBIC_DATABASE_URL`: optional sync URL override for Alembic
- `BACKEND_AUTH_SECRET_KEY`: signing secret for bearer access tokens
- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS`: access-token lifetime in seconds
- `BACKEND_CORS_ALLOWED_ORIGINS`: explicit extra origins if localhost defaults are not enough

Localhost origins are already allowed by default for Flutter web demos.

### Frontend config

The Flutter app does not read the root `.env` file. It uses a compile-time Dart define instead:

- `API_BASE_URL`

If you do not pass `API_BASE_URL`, the Flutter app defaults to `http://localhost:8000`.

## Current Auth Flow

The authenticated MVP uses this local flow:

1. Signup or login calls the backend auth endpoints.
2. The backend returns a bearer access token plus the current session payload.
3. The Flutter app stores the token locally and restores the session on relaunch.
4. Authenticated endpoints resolve the current user from the bearer token.
5. Sign out clears the saved token and returns the app to public routes.

Current limitations:

- no refresh-token flow yet
- no password reset or email verification yet
- no social auth yet
- the development auth secret in `.env.example` is only appropriate for local work and demos

## Demo Notes

The repository is intentionally lightweight for demos:

- food search auto-seeds a small demo dataset the first time food search or food detail is used
- good demo queries include `chicken`, `rice`, `banana`, `oats`, `salmon`, and `yogurt`
- meals, goals, preferences, progress entries, and onboarding choices are created through the app per signed-in account
- there is no large fake production dataset in the repo

If you need to reset an auth session during demos:

- web stores the access token in browser `localStorage`
- desktop and other IO platforms store it in a local `fitness-app/auth_session.json` file under the platform app-data directory

## Local Verification

Backend:

```powershell
cd backend
pytest -q
```

Flutter:

```powershell
cd apps\mobile_web_flutter
flutter test
```

Suggested manual smoke pass after startup:

- signup
- login after sign-out
- onboarding completion
- Today meal logging
- Nutrition overview
- Progress add flows
- More profile/goals/preferences save flows

## Documentation Files

These root files are the current source of truth for repository direction:

- `README.md`
- `CODEX_CONTEXT.md`
- `NEXT_TASK.md`

## Next Likely Milestone

After deployment and demo readiness, the next likely milestone should be true deployment and production-readiness hardening, including stronger auth hardening and release/deployment preparation.

## Final Guardrail

Never create a new root folder for this project. All repository work must remain inside `C:\New folder\fitness-app`.
