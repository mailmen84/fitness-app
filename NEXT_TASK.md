# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: mobile-native readiness and packaging.

## Goal

Prepare the current authenticated MVP for real phone installation and Android-first packaging, while keeping iPhone-ready architecture close behind and leaving web as a secondary access path.

## Current Baseline

The app is now a hardened authenticated MVP across:

- Today
- Add
- Nutrition
- Progress
- More/settings

Recent mobile-readiness work already in place:

- Android and iOS app identity now uses `Fitness App` and `com.fitnessapp.mobile`
- Android and iOS session restore now uses secure storage on phones
- shared scaffold spacing, shell titles, and bottom navigation are less desktop-heavy on small widths
- Android main-manifest internet and cleartext-local-dev support now exist for install testing
- Android release signing can now read a local `android/key.properties` file when one is supplied

The app is closer to a real phone product now, but it still needs a cleaner install-validation pass before this milestone is done.

## Mobile-Native Readiness Requirements

Requirements:

- review remaining dense screens for phone-sized spacing, scrolling, touch targets, and keyboard behavior
- verify the current shell and shared layout feel good on Android-sized widths
- review mobile session restore after app backgrounding and relaunch
- keep web supported, but secondary to phone delivery

## Android Readiness Requirements

Requirements:

- create a local `android/key.properties` file and keystore for a clean release-signing path
- generate and install a local APK
- verify backend connectivity for Android emulator local work and for a hosted demo backend
- confirm the current manifest/network assumptions are acceptable for local install testing
- document the remaining blockers before Play Store or broader distribution

## iPhone-Ready Requirements

Requirements:

- keep architecture and routing friendly to iPhone packaging
- follow up on iPhone signing, transport-policy, and device-install validation
- do not let Android-first work create iPhone-hostile assumptions

## Verification Requirements

Requirements:

- run a practical Android emulator or device smoke pass
- verify login, signup, onboarding, meal logging, settings saves, and session restore on phone-sized surfaces
- confirm sign-out and logged-out route guards still behave correctly after relaunch
- note any remaining small-screen UX issues worth a focused cleanup pass

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

- the project direction is explicitly mobile-first in the source-of-truth docs
- no placeholder mobile package, bundle, or app identity remains in the shipped runners
- phone session persistence uses secure storage on Android and iOS
- the repo documents keystore setup plus APK build and install flow
- at least one clean Android install smoke pass has been completed or the remaining blocker is explicitly documented
- web remains supported, but no longer drives the main product roadmap
- no new root folder was created
