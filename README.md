# fitness-app

`fitness-app` is a cross-platform nutrition and fitness tracking monorepo with a Flutter client and a FastAPI backend. The repository now includes real signup/login auth, the existing onboarding flow, Today meal tracking, food search and meal logging, Nutrition overview, Progress tracking, and a real More/settings area.

## Non-Negotiable Repository Rule

All work must stay inside the existing repository root:

- `C:\New folder\fitness-app`

No new root folder should ever be created. Do not create a nested `fitness-app` folder, and do not move work into a second top-level project directory.

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
        app/
        core/
        features/
      test/
  backend/
    app/
      api/
      application/
      core/
      domain/
      infrastructure/
    alembic/
    tests/
  .env.example
  .gitignore
  docker-compose.yml
  README.md
  CODEX_CONTEXT.md
  NEXT_TASK.md
```

## Completed Milestones

The following milestones are already present in the repository state:

1. Monorepo foundation
- repository root, Flutter app folder, backend folder, env sample, Docker Compose scaffold, and root guidance files

2. Flutter foundation
- shared theme system
- shared widgets
- go_router setup
- Riverpod setup
- app shell and feature-first structure

3. Backend foundation
- FastAPI app centered on `main.py`
- versioned API router
- configuration management
- PostgreSQL connection setup
- SQLAlchemy base and models
- Alembic migration setup
- repository and service layering

4. Authentication and onboarding foundation
- frontend welcome, login, signup, and onboarding flow scaffolds
- frontend Riverpod auth and onboarding state foundations
- backend `/users/me`, `/goals/current`, and `/preferences` foundations that later fed the real auth flow

5. Today dashboard vertical slice
- backend `GET /api/v1/meals?date=YYYY-MM-DD`
- stable day response shape with totals and four meal sections
- frontend Today dashboard with loading, empty, success, and error states

6. Food search and add-to-meal flow
- Flutter add hub, quick add, food search, food detail, and meal detail screens
- backend food search/detail plus meal entry create, update, and delete endpoints
- Today refresh after meal entry mutations
- meal entry nutrition snapshot persistence for stable history

7. Backend integration cleanup and Nutrition overview foundation
- shared frontend API cleanup for Today, meal logging, and nutrition
- backend nutrition overview and macro foundation endpoints
- frontend Nutrition overview screen with day, week, and month range support
- nutrition loading, empty, success, and error states with lightweight summaries and contributors

8. Progress foundation
- backend progress overview, weight list/create, and measurement list/create endpoints
- frontend Progress overview screen with loading, empty, success, and error states
- frontend weight history and measurement history screens
- frontend add-weight and add-measurement entry flows with Progress refresh after save

9. More/settings polish
- frontend More/Profile home with profile summary, settings navigation, and app/runtime info
- frontend profile settings, goals settings, units/preferences, support placeholder, and polished PED placeholder
- frontend reuse of `/users/me`, `/goals/current`, and `/preferences` contracts through a dedicated More repository/controller layer
- thin account-settings API contract coverage scaffolding on the backend side

10. Real authentication
- backend signup, login, password hashing, bearer token issuing, and authenticated current-user resolution
- frontend login, signup, session restore, authenticated routing, and sign-out over the backend auth flow
- existing Today, Add, Nutrition, Progress, and More modules now scoped through the authenticated account

## Current Milestone

Current milestone: real authentication.

This phase assumes the MVP runtime is stable and has now replaced the old dev-only auth path with real multi-user authentication while preserving the working MVP modules.

## Current Product Scope

In scope right now:

- working MVP runtime across Today, Add, Nutrition, Progress, and More/settings on a real local pass
- real signup/login auth with persisted bearer session restore and the existing onboarding flow
- Today dashboard day selection, summary cards, and stable backend meal loading
- food search from a development seed dataset
- food detail viewing
- add a food item to breakfast, lunch, dinner, or snacks for a selected date
- edit or delete an existing meal entry from Today
- Nutrition overview foundation with day, week, and month range selection
- calorie summary, macro summary, nutrient category rows, and top contributors from logged meals
- Progress overview with latest weight, weight trend summary, latest measurements summary, and current goal summary where available
- weight log history plus add-weight flow
- measurement log history plus add-measurement flow
- More/Profile home, profile settings, goals settings, units/preferences, support placeholder, and PED placeholder
- thin backend contracts for users, goals, preferences, foods, meals, nutrition overview, nutrition macro detail, and progress

Still not product-complete:

- auth hardening beyond the current bearer access-token flow
- broader regression coverage across browsers, devices, and automated checks
- advanced nutrition analytics, charts, micronutrient drill-downs, recipes, or barcode flows
- advanced Progress analytics, edit/delete flows, photos, or coaching logic
- production hardening, release packaging, and deployment readiness

## Out of Scope Right Now

Do not assume these are implemented:

- refresh-token rotation or server-side session revocation
- password reset or email verification flows
- social auth
- barcode scanning
- recipes or multi-food saved meals
- advanced unit conversion
- advanced nutrition engines or micronutrient deep dives
- advanced Progress charts, streaks, coaching logic, or photo logging
- offline sync or caching
- a new repository root folder

## Frontend Architecture Principles

- Keep the Flutter app feature-first under `apps/mobile_web_flutter/lib/features/`
- Reuse the shared theme, shared widgets, and router foundation already in `lib/core/`
- Keep business logic out of widgets; use Riverpod controllers and repositories for state and orchestration
- Keep screens clean, minimal, and practical
- Keep API calls in repositories, not directly in widgets
- Keep Today, meal logging, Nutrition, Progress, and More flows backend-ready and mock-friendly
- Avoid adding product features outside the active milestone without explicit instruction

## Backend Architecture Principles

- Keep endpoints thin
- Keep orchestration in services
- Keep persistence logic in repositories
- Keep domain models and schemas grouped by aggregate in `backend/app/domain/`
- Keep the API versioned under `backend/app/api/v1/`
- Keep authenticated endpoints on the bearer-token current-user flow now that real auth is active
- Reuse existing users, goals, preferences, meals, nutrition, and progress contracts before inventing new backend surfaces
- Avoid embedding business workflows directly in route handlers

## Today Screen Contract

The Today screen depends on the backend day contract returned by:

- `GET /api/v1/meals?date=YYYY-MM-DD`

Current response requirements:

- top-level fields:
  - `date`
  - `calories_total`
  - `protein_total`
  - `carbs_total`
  - `fat_total`
- `meal_sections` must always contain exactly four sections:
  - `breakfast`
  - `lunch`
  - `dinner`
  - `snacks`
- each meal section includes:
  - `code`
  - `title`
  - `calories_total`
  - `protein_total`
  - `carbs_total`
  - `fat_total`
  - `entries`
- each entry includes:
  - `id`
  - `meal_id`
  - `food_id`
  - `food_name`
  - `quantity`
  - `unit`
  - `calories`
  - `protein`
  - `carbs`
  - `fat`
  - optional `notes`

Behavioral expectations:

- empty meal sections must still be returned
- Today UI must support loading, empty, success, and error states
- Today should refresh after meal entry create, update, and delete actions

## Setup Notes

Prerequisites:

- Python 3.11+ for the backend
- Flutter SDK compatible with Dart 3.3+ for the client
- Docker Desktop or a compatible Docker engine for PostgreSQL

Windows notes:

- if `python` opens the Microsoft Store instead of running Python, install Python 3.11+ and disable the relevant App execution alias
- if `flutter` is not found, install Flutter and add it to your `PATH`

### Root setup

Create a local `.env` file from `.env.example` before using Docker Compose or the backend local setup:

```powershell
Copy-Item .env.example .env
```

Note:

- `.env` is intentionally not committed and may be missing in a fresh checkout

### Docker

The repository currently uses Docker Compose only for PostgreSQL:

```bash
docker compose up -d postgres
docker compose ps
```

### Backend local run

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .[dev]
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Useful local verification commands once Python is available:

```powershell
pytest -q
```

### Flutter local run

If Flutter platform runners have not been hydrated yet, run this inside `apps/mobile_web_flutter` after Flutter is installed:

```powershell
cd apps\mobile_web_flutter
flutter create . --platforms=android,ios,web,windows,linux,macos
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Notes:

- `API_BASE_URL` is a Flutter compile-time `--dart-define`, not a `.env` variable.
- The default API base URL is already `http://localhost:8000`, which is fine for web/desktop local development.
- The platform runner folders in this repo are still placeholder-only until `flutter create . ...` is run locally.
- `pubspec.lock` will be generated after the first successful `flutter pub get`.
- Android emulators or physical devices may need a different backend host value later, for example `http://10.0.2.2:8000`.

### Current auth note

The working MVP now uses real auth for normal app use:

- frontend login and signup call the backend auth endpoints
- the app restores a saved bearer session on supported platforms
- backend current-user resolution now uses authenticated bearer tokens
- refresh tokens, password reset, and social auth are still intentionally out of scope

### Current environment caveat

In the current Codex environment used to shape this repo, Flutter and Python toolchains may still be unavailable or partially broken. The MVP runtime now works on a real local machine, but some cleanup work here may still be source-inspected rather than fully executed.

## Next Step After The Current Milestone

After the real-auth milestone, the next likely step should be auth stabilization plus demo/deployment readiness from the now-authenticated MVP baseline.

## Final Guardrail

Never create a new root folder for this project. All repository work must remain inside `C:\New folder\fitness-app`.







