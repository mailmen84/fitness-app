# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: real authentication.

## Goal

Replace the old dev-only auth path with real multi-user authentication while preserving the current working MVP structure across Today, Add, Nutrition, Progress, and More.

## Current Baseline

The app now has a stable working MVP runtime across:

- Today
- Add
- Nutrition
- Progress
- More/settings

The next major gap being closed in this phase is real authentication.

Core real-auth implementation is now in place. Any remaining work in this phase should stay focused on auth cleanup, verification, and integration confidence rather than new product scope.

## Backend Authentication Requirements

Work inside:

- `backend`

Requirements:

- implement real signup and login foundations
- use secure password hashing
- issue bearer access tokens appropriate for the current architecture
- resolve the current user from the authenticated token instead of the old debug-header path
- keep endpoints thin
- keep business logic in services
- keep persistence logic in repositories

## Frontend Authentication Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- connect Login and Signup screens to real backend auth
- persist the authenticated session for the current app platforms
- update route guards to use real auth state
- ensure authenticated users reach the app shell and logged-out users are redirected correctly
- keep UI changes minimal and aligned with the existing screens

## Current-User Integration Requirements

Requirements:

- update authenticated endpoints so they resolve the actual signed-in user
- preserve current module behavior for Today, Add, Nutrition, Progress, and More
- keep user-specific data scoped correctly under the authenticated account
- avoid broad rewrites of working feature modules

## Documentation Requirements

Requirements:

- update `README.md`, `CODEX_CONTEXT.md`, and `NEXT_TASK.md` so they reflect the real-authentication milestone
- make it clear that the earlier dev-only auth path is being replaced
- note that the next likely milestone after auth is auth stabilization plus demo/deployment readiness
- keep the repository root guardrails and anti-drift rules intact

## Out Of Scope

Do not add these as part of this phase:

- social auth
- password reset flows unless a truly minimal blocker appears
- production deployment changes
- new product modules
- broad architecture rewrites
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- backend signup, login, password hashing, token issuance, and bearer current-user resolution are in place
- frontend login, signup, session restore, and route guarding use the real auth path
- authenticated endpoints continue working for Today, Add, Nutrition, Progress, and More under the signed-in user
- the root guidance files reflect the real-authentication milestone
- the project is left ready for an auth-stabilization and demo/deployment-readiness pass next
- no new root folder was created

