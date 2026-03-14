# mobile_web_flutter

Mobile-first Flutter client for `fitness-app`.

Primary platform goal:

- Android-first installable phone app
- iPhone-ready architecture second
- web and desktop as secondary access paths

## Current State

The Flutter app currently includes:

- welcome, login, signup, forgot-password, and onboarding flow
- Today, Add, Nutrition, Progress, and More tabs
- backend-backed authenticated routing and session restore
- Riverpod-based feature controllers and repositories
- Android and iOS runners already generated in the project
- package and bundle identity set to `Fitness App` / `com.fitnessapp.mobile`
- secure token storage on Android and iOS
- a first compact-width pass on shared shell spacing, app-bar titling, and bottom navigation behavior

## First-Time Setup

If the native or web runners have not been generated in this checkout yet:

```powershell
flutter create . --platforms=android,ios,web,windows,linux,macos
```

Then install packages:

```powershell
flutter pub get
```

## Run Locally For Phone Work

Android emulator or attached Android device should be the first local target now.

Example Android emulator run:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For Chrome or other secondary access paths:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

You can also pass the full API prefix if you prefer:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Build For Android Packaging Work

Create a local signing config when you want a cleaner release APK path:

```powershell
Copy-Item android\key.properties.example android\key.properties
New-Item -ItemType Directory -Force android\keystore | Out-Null
keytool -genkeypair -v -keystore android\keystore\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then build the APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

For local developer smoke work, the project will still fall back to debug signing if `android\key.properties` is missing. That fallback is only meant to keep local install testing unblocked.

## Secondary Web Build Path

Web remains supported for demos and secondary access.

If a staging web build is still needed:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

## Test Locally

```powershell
flutter test
```

## Runtime Config

The Flutter app uses a compile-time Dart define for the backend URL:

- `API_BASE_URL`

If you omit it, the app defaults to `http://localhost:8000`. That is fine for local browser work, but phone testing should usually point Android emulators at `http://10.0.2.2:8000` or point release/demo builds at a real hosted backend.

## Auth Session Storage

The current MVP stores the access token locally so sessions restore between launches:

- web: browser `localStorage`
- Android and iOS: platform-secure storage
- desktop-style IO platforms: a local `fitness-app/auth_session.json` file in the platform app-data directory

Signing out clears the stored token.

## Current Mobile Gaps

The main gaps before this feels like a true installable phone app are:

- a real release keystore still needs to be created locally and kept out of version control
- launcher icons are still the default generated Flutter assets
- Android local/demo release traffic still assumes temporary cleartext support for non-HTTPS backends
- iPhone signing, transport policy, and device-install validation still need their own follow-up pass
- a final phone-sized polish pass is still needed on some denser detail and settings screens
- the documented APK install flow still needs a clean end-to-end smoke pass on a real device or emulator

## Local Demo Notes

- signup and login are real backend flows
- forgot-password uses the current backend reset challenge flow
- the food search uses a small seeded demo dataset from the backend
- meals, nutrition summaries, progress entries, and settings changes are tied to the signed-in account
- if auth state gets stuck during local demos, sign out or clear the stored token and restart the app
