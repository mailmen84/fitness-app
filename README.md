# fitness-app

`fitness-app` is a mobile-first nutrition and fitness tracking monorepo with a Flutter client and a FastAPI backend. The primary product target is a real installable phone app, with Android first, iPhone-ready architecture second, and web/desktop only as secondary access paths.

## Non-Negotiable Repository Rule

All work must stay inside the existing repository root:

- `C:\New folder\fitness-app`

Do not create a new root folder, do not create a nested `fitness-app` folder, and do not move work into a second top-level project directory.

## Current Phase

Current phase: mobile-native readiness and packaging.

This phase focuses on correcting the project toward real phone-app delivery, tightening mobile UX and session behavior, and preparing the app for Android packaging and installation without broad rewrites or unrelated new features.

## Primary Product Direction

The product direction is now explicit:

- primary target: installable Android app
- secondary target: iPhone-ready architecture and packaging follow-up
- tertiary target: web and desktop remain supported, but they are not the main delivery goal

Existing web staging and browser support still matter for demos and secondary access, but they no longer define the main product direction.

## Current MVP Scope

Working today:

- real signup and login with bearer-token session restore
- onboarding flow after signup
- password reset request plus local reset confirmation flow
- backend email verification challenge foundations for future UI work
- Today dashboard with date selection and meal sections
- Add flow with quick add, food search, food detail, and meal detail
- Nutrition overview with day, week, and month ranges
- Progress overview, weight logging, and measurement logging
- More/Profile home plus profile, goals, and preferences settings
- seeded demo foods for search and meal logging demos
- generated Android and iOS runners already exist in the Flutter project
- Android and iOS app identity now uses `Fitness App` and `com.fitnessapp.mobile` instead of stock Flutter placeholder values
- phone session restore now uses secure storage on Android and iOS

Still intentionally not product-complete:

- refresh tokens or a full server-side revocation flow
- outbound email delivery for password reset or verification
- verified-email enforcement across product features
- social auth
- barcode scanning, recipes, or saved multi-food meal templates
- release automation, CI/CD, and full production infrastructure

## Tech Stack

- Frontend: Flutter, Material 3, Riverpod, go_router, `http`, `flutter_secure_storage`
- Backend: FastAPI, Pydantic, SQLAlchemy, Alembic
- Database: PostgreSQL
- Local infrastructure: Docker Compose for PostgreSQL
- Testing: Flutter widget tests, FastAPI TestClient tests

## Repository Structure

```text
fitness-app/
  apps/
    mobile_web_flutter/
      android/
      ios/
      lib/
      test/
      web/
  backend/
    app/
    alembic/
    tests/
    Dockerfile
    entrypoint.sh
  .env.example
  docker-compose.yml
  staging.nginx.example.conf
  DEPLOYMENT.md
  README.md
  CODEX_CONTEXT.md
  NEXT_TASK.md
```

## Current Mobile Gaps

Before this feels like a truly installable phone app, the current repo still has these concrete gaps:

- a real Android release keystore still needs to be created locally and wired through `apps/mobile_web_flutter/android/key.properties`; the repo now supports that flow, but it cannot ship secrets
- launcher icons are still the default generated Flutter assets, so the packaged app still looks unfinished on a phone home screen
- Android local/demo networking currently relies on `android:usesCleartextTraffic="true"` for non-HTTPS backends; production-ready mobile delivery should move to HTTPS and tighter network policy
- iOS naming is corrected, but iPhone signing, transport policy, and physical-device validation still need their own follow-up pass
- some denser secondary forms and detail screens still need a final phone-sized touch and keyboard polish pass
- the Android APK build/install flow is now documented, but it still needs a clean emulator or real-device smoke pass end to end

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

### 4. Run the Flutter app for phone work

If the platform runners have not been generated yet, hydrate them first:

```powershell
cd apps\mobile_web_flutter
flutter create . --platforms=android,ios,web,windows,linux,macos
```

Then install packages and prefer device-oriented runs first:

```powershell
cd apps\mobile_web_flutter
flutter pub get
flutter test
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For Chrome or other secondary access paths:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

`API_BASE_URL` can be either a backend origin like `http://localhost:8000` or the full API prefix like `http://localhost:8000/api/v1`.

### 5. Build a local Android APK

When you want a cleaner release-style APK path, create a local signing config first:

```powershell
cd apps\mobile_web_flutter
Copy-Item android\key.properties.example android\key.properties
New-Item -ItemType Directory -Force android\keystore | Out-Null
keytool -genkeypair -v -keystore android\keystore\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then build and install:

```powershell
cd apps\mobile_web_flutter
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

If `android\key.properties` is missing, release builds still fall back to the debug key so local smoke work can continue, but that is only a temporary developer path and not a clean distribution setup.

## Environment Notes

### Backend config

The root `.env` file configures the backend. The most relevant settings are:

- `BACKEND_ENVIRONMENT`
- `BACKEND_DATABASE_URL`
- `BACKEND_ALEMBIC_DATABASE_URL`
- `BACKEND_AUTH_SECRET_KEY`
- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS`
- `BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS`
- `BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS`
- `BACKEND_DOCS_ENABLED`
- `BACKEND_CORS_ALLOWED_ORIGINS`
- `BACKEND_CORS_ALLOW_ORIGIN_REGEX`
- `BACKEND_RUN_MIGRATIONS`

### Frontend config

The Flutter app uses compile-time Dart defines rather than the root `.env` file.

Current runtime define:

- `API_BASE_URL`

For Android emulator work, `10.0.2.2` is usually the local host bridge. For web, `localhost` remains fine. Hosted web still exists as a secondary path, not the main product target.

## Secondary Web/Deployment Path

Web staging and hosted browser access remain useful for demos, QA, and secondary access.

See [DEPLOYMENT.md](DEPLOYMENT.md) for the AWS staging plan, but treat it as a secondary delivery path behind the primary mobile-native goal.

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

Suggested manual smoke pass for the current mobile-first milestone:

- Android emulator or physical-device install and first launch
- signup or login on a phone-sized screen
- onboarding completion on a phone-sized screen
- Today meal logging on phone
- Nutrition overview on phone
- Progress save flows on phone
- More profile/goals/preferences save flows on phone
- background the app, relaunch it, and confirm session restore on phone
- sign out, relaunch, and confirm the logged-out route guard state

## Documentation Files

These root files are the current source of truth for repository direction:

- `README.md`
- `CODEX_CONTEXT.md`
- `NEXT_TASK.md`
- `DEPLOYMENT.md`

## Next Likely Milestone

After mobile-native readiness and packaging, the next likely milestone should be Android install validation and first packaged-device smoke passes.

## Final Guardrail

Never create a new root folder for this project. All repository work must remain inside `C:\New folder\fitness-app`.
