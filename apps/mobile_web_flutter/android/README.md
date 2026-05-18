# Android Packaging Guide

This Android runner is part of the mobile-first Flutter client. Android installability is the immediate target; web remains secondary.

## Current Android Identity

- application id: `com.fitnessapp.mobile`
- app label: `Fitness App`
- main activity package: `com.fitnessapp.mobile`

## Local Toolchain Requirements

Before the first APK build attempt, confirm:

- Flutter is installed and `flutter doctor -v` is mostly healthy
- Android SDK platform 36 is installed
- the Android Build-Tools version requested by `flutter doctor -v` is installed
- Java 17 is available for Gradle
- on Windows, Developer Mode is enabled if Flutter reports symlink/plugin issues

## Create The Local Keystore

From `apps/mobile_web_flutter`:

```powershell
New-Item -ItemType Directory -Force android\keystore | Out-Null
keytool -genkeypair -v -keystore android\keystore\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Suggested values when prompted:

- first and last name: your name or team name
- organizational unit: optional
- organization: optional
- city/state/country: your real values
- password: use a strong password you can keep locally

Keep the generated `.jks` file outside version control.

## Fill `android/key.properties`

From `apps/mobile_web_flutter`:

```powershell
Copy-Item android\key.properties.example android\key.properties
```

Then edit `android\key.properties` so it points at your local keystore:

```text
storeFile=../keystore/upload-keystore.jks
storePassword=<your keystore password>
keyAlias=upload
keyPassword=<your key password>
```

Notes:

- `storeFile` is relative to `android/app`
- `android/key.properties` must stay local and must not be committed
- if `android/key.properties` is missing, release builds fall back to the debug key only to keep local smoke work unblocked

## Build The APK

For a real release-style local APK attempt, prefer a hosted backend URL:

```powershell
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

For emulator-only local backend work:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The Android manifest now allows cleartext traffic only for local emulator/dev hosts like `10.0.2.2` and `localhost`. Physical-phone testing should use a reachable backend URL, ideally HTTPS.

## Install The APK

With a device connected and USB debugging enabled:

```powershell
adb devices
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

If Android blocks the install, allow app installs from your current source or use the device file manager to open the APK manually.

## Android Device Smoke Checklist

Run this on a real Android phone if possible:

1. Install the APK and confirm the launcher label is `Fitness App`.
2. Open the app and confirm the welcome screen loads without a crash.
3. Sign up with a fresh account and complete onboarding.
4. Sign out, then log back in with the same account.
5. Open Today, change days, and confirm the dashboard loads.
6. Open Add, search for a seeded food, and save it into a meal.
7. Re-open Today and confirm the saved meal appears.
8. Open Nutrition and confirm day/week/month ranges load.
9. Open Progress, add a weight entry, and add a measurement entry.
10. Open More, update profile/goals/preferences, and confirm saves succeed.
11. Background the app, relaunch it, and confirm the session restores.
12. Sign out, relaunch again, and confirm the app stays logged out.

## Known Remaining Blockers

- launcher icons are still default Flutter assets
- this machine still needs Android SDK platform 36 and the Build-Tools version required by `flutter doctor -v` for a clean local build
- physical-phone validation still depends on a reachable backend URL
- Play Store packaging, app signing management, and iPhone validation are still future work


