# CODEX_CONTEXT

This file is the Codex-oriented source of truth for the repository state as of March 12, 2026.

## Project Identity

Project: `fitness-app`

Purpose:

- build a Flutter client and FastAPI backend for a nutrition and fitness tracking product
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
- frontend local auth and onboarding state
- backend `/users/me`, `/goals/current`, and `/preferences` foundations
- dev-only current-user placeholder on backend

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

7. Backend integration cleanup and Nutrition overview foundation
- shared frontend API seams cleaned for Today, meal logging, and nutrition
- backend nutrition overview and macro foundation endpoints
- frontend Nutrition overview screen with day, week, and month ranges
- lightweight calorie, macro, category, and contributor summaries

8. Progress foundation
- frontend Progress overview, weight history, add-weight, measurement history, and add-measurement screens
- backend progress overview plus weight and measurement list/create endpoints
- Progress loading, empty, success, and error states with post-save refresh

9. More/settings polish
- frontend More/Profile home
- profile settings, goals settings, units/preferences, support placeholder, and polished PED placeholder screens
- frontend reuse of `/users/me`, `/goals/current`, and `/preferences` through the More repository/controller layer
- account/settings test scaffolding added around the thin backend contracts

## Current Milestone

Current milestone: post-MVP polish and cleanup.

Status:

- the core MVP structure is now present across Today, meal logging, Nutrition, Progress, and More/settings
- a working MVP runtime has now been achieved on a real local pass across Today, Add, Nutrition, Progress, and More/settings
- the current job is not to add a new product module
- the current job is to improve polish, cleanup, stability, consistency, and maintainability from that baseline

## What Already Exists

### Frontend

- app shell with bottom navigation
- welcome, login, signup, onboarding goal, stats, activity, and target screens
- Today screen backed by the backend day meals contract
- add hub, quick add, food search, food detail, and meal detail screens
- Riverpod controllers for Today loading, food search, meal logging flow, Nutrition overview loading, Progress loading/mutations, and More/settings loading/mutations
- shared API client using the current environment base URL and dev-only auth headers
- navigation from Today meal cards and quick actions into the add flow
- Today refresh after meal entry create, update, and delete
- Nutrition overview screen with day, week, and month range support, summary cards, category rows, and top contributors
- Progress overview screen with latest weight, weight trend, latest measurements, and current goal summary
- weight history and add-weight flow
- measurement history and add-measurement flow
- More/Profile home with profile summary, navigation rows, settings screens, support placeholder, and polished PED placeholder
- working MVP runtime on a real local pass across Today, Add, Nutrition, Progress, and More/settings

### Backend

- FastAPI app with versioned routes
- current-user dev placeholder via `X-Debug-User-Email` and `X-Debug-User-Name`
- users, goals, and preferences foundation endpoints
- foods endpoints:
  - `GET /api/v1/foods/search?q=`
  - `GET /api/v1/foods/{food_id}`
- meals endpoints:
  - `GET /api/v1/meals?date=YYYY-MM-DD`
  - `POST /api/v1/meals/entries`
  - `PATCH /api/v1/meals/entries/{entry_id}`
  - `DELETE /api/v1/meals/entries/{entry_id}`
- nutrition endpoints:
  - `GET /api/v1/nutrition/overview?range=day&date=YYYY-MM-DD`
  - `GET /api/v1/nutrition/macro/{macro_type}?range=day&date=YYYY-MM-DD`
- progress endpoints:
  - `GET /api/v1/progress/overview`
  - `GET /api/v1/progress/weight`
  - `POST /api/v1/progress/weight`
  - `GET /api/v1/progress/measurements`
  - `POST /api/v1/progress/measurements`
- meal entry snapshot persistence for calories, protein, carbs, and fat
- development food seed dataset for search and testing
- lightweight Nutrition aggregation for totals, targets, category rows, and contributors
- lightweight Progress aggregation for latest weight, previous-entry delta, latest measurement snapshot rows, and current goal summary when available

## Current Functional Focus

The active focus is post-MVP polish and cleanup.

That means the next work should:

- clean up low-risk inconsistencies in Flutter screens, copy, spacing, button labels, and card alignment
- smooth out save and refresh behavior without introducing lifecycle regressions
- improve backend response and error-handling consistency where useful
- keep documentation practical while avoiding a new product vertical slice

## Backend Meal Rules

These rules are currently expected and should not drift without explicit instruction:

- meal sections are fixed to:
  - breakfast
  - lunch
  - dinner
  - snacks
- `GET /api/v1/meals?date=...` must always return all four sections, even if empty
- a meal container should be reused or created per user, date, and meal section when inserting entries
- meal entries must persist snapshot values for:
  - `food_name`
  - `calories_total`
  - `protein_total`
  - `carbs_total`
  - `fat_total`
- meal history should stay stable even if food records change later
- advanced unit conversion is not in scope yet; current logic is based on the food's default serving unit

## Frontend Implementation Rules

- use the existing shared theme and shared widgets first
- keep feature screens focused on composition and user interaction
- keep API calls inside repositories, not directly inside widgets
- keep selected date and target meal section in Riverpod state for the add flow
- keep Today as the source of post-mutation refresh for the selected day
- keep Nutrition on the backend-backed overview contract already in the repo
- keep Progress on the backend-backed overview, weight, and measurement contracts already in the repo
- keep More/settings on the existing users, goals, and preferences contracts already in the repo
- prefer practical, explicit navigation over speculative abstractions
- keep placeholder areas clearly labeled if they are not part of the active slice

## Must Not Be Implemented Unless Explicitly Requested

Do not add these on your own:

- production auth or token issuing
- backend login or signup APIs
- secure credential flows
- advanced nutrition analytics, micronutrient deep dives, or chart-heavy nutrition surfaces
- advanced Progress analytics, photo logging, or coaching systems
- barcode scanning
- recipes
- meal templates or repeat-yesterday logic
- advanced search ranking or external food providers
- advanced unit conversion or nutrition calculation engines
- unrelated workout, coaching, social, or subscription features
- a new repository root folder

## Temporary Auth Rule

Current auth is dev-only.

Meaning:

- frontend uses preview or local auth state for flow gating
- backend current-user resolution uses debug headers or configured dev defaults
- this is a temporary implementation and must not be treated as production auth

## Expected Next Step After The Current Milestone

After post-MVP polish and cleanup, the next step should come from the cleaner baseline: deepen automated verification and regression coverage or intentionally choose the next product slice.
