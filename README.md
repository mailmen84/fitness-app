# fitness-app

A clean monorepo starter for a cross-platform Flutter client and a FastAPI backend.

## Structure

```text
fitness-app/
  apps/
    mobile_web_flutter/   # Flutter app (Android, iOS, web, desktop)
  backend/                # FastAPI service
  .env.example
  .gitignore
  docker-compose.yml
```

## Applications

### Flutter app

Location: `apps/mobile_web_flutter`

Goals of this scaffold:

- feature-first `lib/` structure
- shared app configuration, routing, and theming
- starter widget test
- folders prepared for Android, iOS, web, Linux, macOS, and Windows

Because Flutter is not installed in this environment, native runner files were not generated automatically. Once Flutter is available, run this inside `apps/mobile_web_flutter` to hydrate the platform runners:

```bash
flutter create . --platforms=android,ios,web,windows,linux,macos
```

Then start the app with:

```bash
flutter pub get
flutter run -d chrome
```

### FastAPI backend

Location: `backend`

Goals of this scaffold:

- layered architecture
- environment-based settings
- versioned API router
- starter health endpoint
- PostgreSQL-ready infrastructure module

Create a virtual environment, install dependencies, and start the server:

```bash
python -m venv .venv
.venv\\Scripts\\activate
pip install -e .
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The server will expose:

- `GET /api/v1/health`
- `GET /docs`

## Docker

Start PostgreSQL from the repo root:

```bash
docker compose up -d postgres
```

The default connection details are stored in `.env.example`.
