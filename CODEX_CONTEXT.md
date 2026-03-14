# CODEX_CONTEXT

This file is the Codex-oriented source of truth for the repository state as of March 14, 2026.

## Project Identity

Project: `fitness-app`

Purpose:

- build and maintain a mobile-first Flutter client plus FastAPI backend for a nutrition and fitness tracking product
- optimize first for a real installable Android app
- keep the architecture iPhone-ready as the second platform priority
- keep web and desktop available only as secondary access paths
- preserve a clean monorepo structure and predictable engineering handoff state

## Repository Root

All work must stay inside this exact root path:

- `C:\New folder\fitness-app`

Hard rule:

- do not create any new root folder
- do not create a nested `fitness-app` folder
- do not relocate work outside this repository unless explicitly requested

## Frontend Architecture Rules

- keep Flutter code inside `apps/mobile_web_flutter`
- keep the code feature-first under `lib/features/`
- keep shared infrastructure in `lib/core/`
- keep navigation in go_router
- keep state in Riverpod
- keep UI logic thin; move orchestration into controllers, providers, and repositories
- reuse the existing theme and shared widgets before creating new UI primitives
- prefer phone-first UX decisions before web or desktop convenience
- keep web and desktop support secondary unless the active milestone explicitly requires them
- do not add product flows beyond the active milestone unless explicitly requested

## Backend Architecture Rules

- keep backend code inside `backend`
- keep the app centered on `backend/app/main.py`
- keep endpoints versioned under `backend/app/api/v1/`
- keep endpoints thin
- keep orchestration in services
- keep persistence in repositories
- keep domain models and schemas grouped by aggregate under `backend/app/domain/`
- keep migrations in Alembic
- preserve stable response contracts once a vertical slice is introduced
- do not move business logic into route handlers

## Completed Milestones

These milestones are already present in the repository state:

1. Monorepo foundation
- monorepo root
- Flutter app folder
- backend folder
- env sample
- Docker Compose scaffold
- root guidance files

2. Flutter foundation
- reusable theme system
- shared widgets
- go_router setup
- Riverpod setup
- app shell and feature-first structure

3. Backend foundation
- FastAPI app structure
- versioned router
- PostgreSQL connection setup
- SQLAlchemy base and models
- migration setup
- layered repository and service structure

4. Authentication and onboarding foundation
- frontend welcome, login, signup, and onboarding flow scaffolds
- frontend auth and onboarding state foundations
- backend `/users/me`, `/goals/current`, and `/preferences` foundations that later fed the real auth path

5. Today dashboard vertical slice
- backend day meals contract
- frontend Today dashboard with summary cards and meal sections
- loading, empty, success, and error states for Today

6. Food search and add-to-meal flow
- Flutter add hub, quick add, food search, food detail, and meal detail screens
- backend food search and food detail endpoints
- backend meal entry create, update, and delete endpoints
- Today refresh after meal entry mutations
- meal entry nutrition snapshot persistence

7. Nutrition overview foundation
- backend nutrition overview and macro endpoints
- frontend Nutrition overview screen with day, week, and month range support
- lightweight calorie, macro, category, and contributor summaries

8. Progress foundation
- frontend Progress overview, weight history, add-weight, measurement history, and add-measurement screens
- backend progress overview plus weight and measurement list/create endpoints
- Progress loading, empty, success, and error states with post-save refresh

9. More/settings polish
- frontend More/Profile home
- profile settings, goals settings, units/preferences, support placeholder, and PED placeholder screens
- frontend reuse of `/users/me`, `/goals/current`, and `/preferences` through the More repository/controller layer
- account/settings test scaffolding around the thin backend contracts

10. Real authentication
- backend signup, login, password hashing, bearer token issuing, and current-session restore
- backend authenticated current-user resolution over bearer access tokens
- frontend login, signup, persisted session restore, authenticated route guarding, and sign-out
- current MVP modules now operate under the authenticated user account

11. Deployment and demo readiness cleanup
- local env/config guidance is clearer
- startup docs for Docker, backend, and Flutter are easier to follow
- demo-seed behavior and auth limitations are documented more explicitly
- low-risk runtime wording and setup guidance are cleaner for demos

12. Auth hardening and security basics
- backend access tokens now carry stronger security claims and token-version groundwork
- backend password reset request/confirm foundations exist with hashed one-time tokens
- backend email verification challenge foundations exist for future UI and delivery work
- frontend login now exposes a forgot-password route and the reset flow restores a real session
- auth-focused backend test coverage and lightweight frontend password-reset test scaffolding were expanded

13. Deployment readiness and production planning cleanup
- deployment docs now describe a practical hosting shape for Flutter web, FastAPI, and PostgreSQL
- environment separation is clearer between local-style and hosted environments
- backend CORS defaults no longer silently carry localhost assumptions into hosted environments
- startup, handoff, and demo-readiness docs are more explicit across the repo

14. Simple AWS staging deployment plan
- the repo documents a single preferred AWS staging shape for one developer
- backend container startup and same-origin reverse-proxy support files exist for a Lightsail-style deployment
- the staging plan stays lightweight and avoids broad infrastructure automation

15. Product direction correction to mobile-first delivery
- the primary product target is now a real installable phone app
- Android is the first packaging target
- iPhone-readiness is the second platform priority
- web and desktop remain supported only as secondary access paths

## Current Phase

Current phase: mobile-native readiness and packaging.

Status:

- the project is a hardened authenticated MVP with working Android and iOS runners present
- the active work is to close the gap between that MVP and a true installable Android-first phone app
- basic Android/iOS package identity, phone-secure session storage, and a first compact-width shell pass are now in place
- web and desktop still exist, but they no longer define the main product direction

## What Already Exists

### Frontend

- app shell with bottom navigation
- welcome, login, signup, forgot-password, and onboarding screens
- Today screen backed by the backend day meals contract
- add hub, quick add, food search, food detail, and meal detail screens
- Nutrition overview screen with day, week, and month range support
- Progress overview plus weight and measurement flows
- More/Profile home plus profile, goals, preferences, support, and PED routes
- shared API client using bearer access tokens
- authenticated route guarding and session restore
- Android and iOS project runners already present in the Flutter app
- Android and iOS app identity now uses `Fitness App` / `com.fitnessapp.mobile` instead of Flutter placeholder defaults
- Android and iOS session restore now uses secure token storage on phones and file storage on desktop-style IO platforms
- shared shell spacing, titles, and bottom navigation now have a first compact-width pass for smaller screens
- web build path still available for secondary access and demos

### Backend

- FastAPI app with versioned routes
- auth endpoints for signup, login, current-session restore, password reset, and email-verification groundwork
- users, goals, preferences, foods, meals, nutrition, progress, health, and system endpoints
- PostgreSQL persistence with Alembic migrations
- seeded demo food data for search and local smoke tests
- current-user resolution from bearer tokens for authenticated routes
- token-version checks that prepare for future session invalidation work
- backend Dockerfile plus a migration-aware container entrypoint

## Current Functional Focus

The active focus is mobile-native readiness and packaging.

That means current work should:

- prioritize phone-sized UX and installable-app behavior first
- review navigation, layout density, touch targets, keyboard handling, and mobile session behavior screen by screen
- make Android packaging and APK install readiness explicit
- keep iPhone architecture and packaging readiness close behind Android work
- treat web and desktop as secondary access paths unless the milestone explicitly needs them
- avoid broad rewrites, unrelated product work, or new feature-module expansion

## Current Mobile Gaps

The current repo still has these concrete mobile-readiness gaps:

- a real Android release keystore still needs to be created locally and referenced from `android/key.properties`
- launcher icons are still the default generated Flutter assets
- Android local/demo release traffic still relies on temporary cleartext support for non-HTTPS backends
- iPhone signing, transport policy, and device-install validation still need their own follow-up pass
- some denser secondary forms and detail screens still need a final small-screen touch and keyboard polish pass
- the APK build/install flow is now documented, but it still needs a clean emulator or physical-device smoke pass

## Current Auth Rule

The working app uses real auth for normal use and is already hardened beyond the original MVP path.

Meaning:

- frontend auth state is driven by backend signup, login, password reset, and current-session restore
- frontend route guarding depends on the authenticated bearer session
- backend current-user resolution uses bearer access tokens instead of debug headers
- password-reset completion invalidates older access tokens for that account through token-version checks
- refresh tokens, delivery-backed email flows, and broader session-management infrastructure are still future work

## Must Not Be Implemented Unless Explicitly Requested

Do not add these on your own:

- broad web-first pivots that pull the product away from phone delivery
- full cloud infrastructure automation or vendor-specific production stacks
- refresh-token rotation or full server-side session revocation systems
- outbound email delivery infrastructure or broad notification systems
- social auth
- barcode scanning
- recipes
- advanced nutrition analytics or chart-heavy progress coaching
- unrelated workout, coaching, social, or subscription features
- a new repository root folder

## Expected Next Step After This Phase

After mobile-native readiness and packaging, the next likely milestone should be Android install validation and phone-device stabilization.
