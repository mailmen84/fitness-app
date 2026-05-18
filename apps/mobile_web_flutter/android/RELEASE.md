# Android Release Cheat Sheet

Short reference for cutting a signed APK. The full walk-through with every
flag and known gotcha lives in [README.md](README.md); this file is the
condensed checklist to run before each release.

## One-Time Setup

```powershell
# from apps/mobile_web_flutter
New-Item -ItemType Directory -Force android\keystore | Out-Null

keytool -genkeypair -v `
  -keystore android\keystore\upload-keystore.jks `
  -alias upload `
  -keyalg RSA -keysize 2048 -validity 10000
```

Then copy `android/key.properties.example` to `android/key.properties` and
fill in `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`. Both
`keystore/` and `key.properties` are git-ignored. Back the JKS up somewhere
safe (a password manager attachment is fine); losing it means you cannot
push updates to anyone who already installed the previous APK.

## Generate Launcher Icons (when artwork changes)

```powershell
flutter pub get
dart run flutter_launcher_icons
```

Source images live in `assets/icon/`. Commit generated native icons with
the source replacements.

## Build A Release APK

```powershell
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Output: `build\app\outputs\flutter-apk\app-release.apk`.

For LAN testing instead of a hosted backend, use the host's IP:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.20.50:8000
```

## Install On A Phone

1. Enable "Install unknown apps" for your file manager or browser on the
   target Android phone.
2. Copy the APK over USB, AirDroid, or a chat app.
3. Tap the APK on the phone and accept the install prompt.

## Pre-Release Smoke

- launch from the home screen icon
- log in with a real backend account
- add one food via search, one via barcode scan, one via custom form
- edit and delete a meal entry
- open `More -> Diet setup` and confirm the calculated targets persist
- close and reopen the app to confirm session restore

## Secrets Reminder

`key.properties`, `upload-keystore.jks`, and any `.env` file with backend
credentials must never be committed. Treat them as deploy-only assets and
keep their values out of chat and tickets.
