# backend

FastAPI backend for `fitness-app`.

## What This Backend Contains Today

- versioned FastAPI routes under `app/api/v1`
- layered services and repositories
- PostgreSQL persistence via SQLAlchemy
- Alembic migrations
- thin contracts for users, goals, preferences, foods, meals, nutrition, and progress
- temporary dev-only current-user resolution for local development

## Prerequisites

- Python 3.11+
- PostgreSQL running locally through the root Docker Compose setup
- root-level `.env` created from `..\.env.example`

If `python` on Windows opens the Microsoft Store instead of running Python, install Python 3.11+ and disable the relevant App execution alias before continuing.

## Prepare The Environment

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose up -d postgres
docker compose ps
```

This repository currently uses Docker Compose only for PostgreSQL. The backend itself is run locally from the `backend` folder.

## Run The Backend Locally

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .[dev]
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The local API will then be available at:

- `http://localhost:8000`
- docs: `http://localhost:8000/docs`
- redoc: `http://localhost:8000/redoc`

## Run Backend Tests Locally

With the virtual environment active:

```powershell
pytest -q
```

## Flutter Local Run

Flutter is run from `apps/mobile_web_flutter` in the repository root. For the current frontend instructions:

```powershell
cd ..\apps\mobile_web_flutter
flutter create . --platforms=android,ios,web,windows,linux,macos
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Current Route Surface

- `GET /api/v1/health`
- `GET /api/v1/system/foundation`
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

## Dev-Only Auth Limitation

Current auth is intentionally temporary:

- there are no login or signup API endpoints yet
- there is no token issuing yet
- the backend resolves the current user from `X-Debug-User-Email` and `X-Debug-User-Name` headers or the dev defaults in the backend settings
- this is suitable only for local development and repository scaffolding

## Notes

- PostgreSQL is the default database target.
- Local CORS is enabled by default for `localhost`, `127.0.0.1`, and `[::1]` on any port so Flutter web can call the API during development.
- Use `BACKEND_CORS_ALLOWED_ORIGINS` to add explicit non-local origins later without changing code.
- `GET /api/v1/meals?date=...` always returns four meal sections for the selected date, even when they are empty.
- Food search uses a small development seed dataset on first use so search is testable before admin tooling exists.
- Meal entry writes persist snapshot calories, protein, carbs, and fat onto the entry for stable history.
- Auth, token issuing, barcode scanning, recipes, and advanced nutrition or progress logic are intentionally deferred.
