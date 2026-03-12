# CODEX_CONTEXT

This file is the Codex-oriented source of truth for the repository state as of March 12, 2026.

## Project Identity

Project: `fitness-app`

Purpose:

- build and maintain a Flutter client plus FastAPI backend for a nutrition and fitness tracking product
- move in vertical slices without drifting into unrequested product scope
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
- keep the UI clean, minimal, and practical
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

## Current Phase

Current phase: auth hardening and security basics.

Status:

- the project is an authenticated working MVP with demo-ready core flows
- the active work is to strengthen auth robustness, session safety, and account-security foundations without broad rewrites
- this phase is not for adding unrelated product modules or full production infrastructure

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

### Backend

- FastAPI app with versioned routes
- auth endpoints for signup, login, current-session restore, password reset, and email-verification groundwork
- users, goals, preferences, foods, meals, nutrition, progress, health, and system endpoints
- PostgreSQL persistence with Alembic migrations
- seeded demo food data for search and local smoke tests
- current-user resolution from bearer tokens for authenticated routes
- token-version checks that prepare for future session invalidation work

## Current Functional Focus

The active focus is auth hardening and security basics.

That means current work should:

- keep bearer-token auth predictable and easier to evolve safely
- improve password validation, error handling, and low-risk security defaults
- keep password reset and email verification groundwork practical for local work
- improve auth UX where useful without redesigning the app
- avoid broad rewrites, production infrastructure work, or unrelated product features

## Current Auth Rule

The working app uses real auth for normal use, and that auth is being strengthened.

Meaning:

- frontend auth state is driven by backend signup, login, password reset, and current-session restore
- frontend route guarding depends on the authenticated bearer session
- backend current-user resolution uses bearer access tokens instead of debug headers
- password-reset completion invalidates older access tokens for that account through token-version checks
- refresh tokens, delivery-backed email flows, and broader session-management infrastructure are still future work

## Must Not Be Implemented Unless Explicitly Requested

Do not add these on your own:

- production deployment infrastructure beyond documentation or setup notes
- refresh-token rotation or full server-side session revocation systems
- outbound email delivery infrastructure or broad notification systems
- social auth
- barcode scanning
- recipes
- advanced nutrition analytics or chart-heavy progress coaching
- unrelated workout, coaching, social, or subscription features
- a new repository root folder

## Expected Next Step After This Phase

After auth hardening and security basics, the next likely milestone should be deployment readiness and production infrastructure planning.
