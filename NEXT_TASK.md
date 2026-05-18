# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: Android packaging and device validation.

## Goal

Prepare the current authenticated MVP for a real locally installable Android build and define the exact validation steps for the first physical-phone smoke pass, while keeping web as a secondary access path.

## Current Baseline

The app is now a hardened authenticated MVP across:

- Today
- Add
- Nutrition
- Progress
- More/settings

Recent Android-packaging work already in place:

- Android app identity now uses `Fitness App` and `com.fitnessapp.mobile`
- Android and iOS session restore now uses secure storage on phones
- Android main-manifest internet permission exists for release builds
- Android network cleartext allowance is now narrowed to local emulator/dev hosts via network security config
- Android release signing can now read a local `android/key.properties` file when one is supplied
- the repo now includes an Android-specific packaging guide and device smoke checklist

The app is close to a first real APK attempt now, but final machine/tooling validation still needs to happen.

## Android Packaging Requirements

Requirements:

- confirm `flutter doctor -v` is healthy enough for Android builds on the target machine
- create a local `android/key.properties` file and keystore for a clean release-signing path
- generate a local release APK with `flutter build apk --release`
- install the APK on a real Android phone or emulator with `adb install`
- verify backend connectivity for the chosen validation backend URL

## Android Device Validation Requirements

Requirements:

- validate login and signup on device
- validate onboarding completion on device
- validate Today loading and meal logging on device
- validate Add food search and save on device
- validate Nutrition ranges on device
- validate Progress save flows on device
- validate More profile/goals/preferences saves on device
- validate background/relaunch session restore and logout behavior on device

## Supporting Requirements

Requirements:

- keep web supported, but secondary to Android installability
- keep secrets out of the repo
- document the exact keystore and `android/key.properties` steps for one developer
- document any remaining blockers before broader Android distribution

## Out Of Scope

Do not add these as part of this phase:

- new product modules
- barcode scanning
- recipes
- broad architecture refactors
- full production deployment work
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- the active docs explicitly describe Android packaging and device validation as the current phase
- the local keystore and `android/key.properties` path are documented clearly
- the project is ready for a real `flutter build apk --release` attempt on a correctly configured machine
- a practical Android device smoke checklist exists for the current MVP flows
- the remaining blockers before a clean phone install are explicitly documented
- web remains supported, but no longer drives the main product roadmap
- no new root folder was created
