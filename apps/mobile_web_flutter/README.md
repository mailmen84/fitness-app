# mobile_web_flutter

Authenticated Flutter client for `fitness-app`.

## Current State

The Flutter app currently includes:

- welcome, login, signup, forgot-password, and onboarding flow
- Today, Add, Nutrition, Progress, and More tabs
- backend-backed authenticated routing and session restore
- Riverpod-based feature controllers and repositories

## First-Time Setup

If the native or web runners have not been generated in this checkout yet:

```powershell
flutter create . --platforms=android,ios,web,windows,linux,macos
```

Then install packages:

```powershell
flutter pub get
```

## Run Locally

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

You can also pass the full API prefix if you prefer:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Build For AWS Staging

For the recommended same-origin Lightsail staging setup, build the app against the public staging origin:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

Deployment notes for the generated web build:

- copy `build/web` to the staging instance web root
- serve it from Nginx or an equivalent web server
- configure SPA fallback so routes like `/login` or `/more/profile` return `index.html`
- let the reverse proxy forward `/api/` to the backend container on the same host

## Test Locally

```powershell
flutter test
```

## Runtime Config

The Flutter app uses a compile-time Dart define for the backend URL:

- `API_BASE_URL`

If you omit it, the app defaults to `http://localhost:8000`. That default is useful for local work, but AWS staging should set the public staging URL explicitly.

## Auth Session Storage

The current MVP stores the access token locally so sessions restore between launches:

- web: browser `localStorage`
- IO and desktop platforms: a local `fitness-app/auth_session.json` file in the platform app-data directory

Signing out clears the stored token.

## Local Demo Notes

- signup and login are real backend flows
- forgot-password uses the current backend reset challenge flow
- the food search uses a small seeded demo dataset from the backend
- meals, nutrition summaries, progress entries, and settings changes are tied to the signed-in account
- if auth state gets stuck during local demos, sign out or clear the stored token and restart the app

## Known Limits

- no refresh tokens yet
- no user-facing email verification screen yet
- no social auth yet
- no offline mode or caching layer yet
