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
- Android-specific keystore, APK, and device-validation guidance in [android/README.md](C:/New folder/fitness-app/apps/mobile_web_flutter/android/README.md)

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

See [android/README.md](C:/New folder/fitness-app/apps/mobile_web_flutter/android/README.md) for the full signing, build, install, and smoke-test flow.

Short version:

```powershell
Copy-Item android\key.properties.example android\key.properties
New-Item -ItemType Directory -Force android\keystore | Out-Null
keytool -genkeypair -v -keystore android\keystore\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

For local developer smoke work, the project will still fall back to debug signing if `android\key.properties` is missing. That fallback is only meant to keep local install testing unblocked.

## Tooling Notes

For a clean Android build path, the local machine should satisfy `flutter doctor -v`.

On the Windows validation machine used in this repo session, the current blockers reported by Flutter are:

- Android SDK platform 36 still needs to be installed
- if Flutter reports plugin symlink issues, Windows Developer Mode should be enabled

## Secondary Web Build Path

Web remains supported for demos and secondary access.

If a staging web build is still needed:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

## Test Locally

```powershell
flutter test
flutter doctor -v
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

## Current Android Gaps

The main gaps before this feels like a clean installable Android app are:

- a real local release keystore still needs to be created and kept out of version control
- launcher icons are still the default generated Flutter assets
- physical-phone validation still needs a reachable backend URL, ideally HTTPS
- this machine still needs Android SDK platform 36 before a clean local APK build can be completed
- the first successful end-to-end `flutter build apk --release` plus `adb install` pass still needs to be completed

## Local Demo Notes

- signup and login are real backend flows
- forgot-password uses the current backend reset challenge flow
- the food search uses a small seeded demo dataset from the backend
- meals, nutrition summaries, progress entries, and settings changes are tied to the signed-in account
- if auth state gets stuck during local demos, sign out or clear the stored token and restart the app
