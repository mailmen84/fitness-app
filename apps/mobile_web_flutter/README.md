# mobile_web_flutter

Authenticated Flutter client for `fitness-app`.

## Current State

The Flutter app currently includes:

- welcome, login, signup, and onboarding flow
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

## Test Locally

```powershell
flutter test
```

## Runtime Config

The Flutter app uses a compile-time Dart define for the backend URL:

- `API_BASE_URL`

If you omit it, the app defaults to `http://localhost:8000`.

## Auth Session Storage

The current MVP stores the access token locally so sessions restore between launches:

- web: browser `localStorage`
- IO and desktop platforms: a local `fitness-app/auth_session.json` file in the platform app-data directory

Signing out clears the stored token.

## Local Demo Notes

- signup and login are real backend flows
- the food search uses a small seeded demo dataset from the backend
- meals, nutrition summaries, progress entries, and settings changes are tied to the signed-in account
- if auth state gets stuck during local demos, sign out or clear the stored token and restart the app

## Known Limits

- no refresh tokens yet
- no password reset or social auth yet
- no offline mode or caching layer yet
