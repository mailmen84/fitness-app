# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: post-MVP polish and cleanup.

## Goal

Improve the existing working MVP so it feels more stable, consistent, usable, and maintainable without introducing major new product features.

## Current Baseline

The app now has a working MVP runtime across:

- Today
- Add
- Nutrition
- Progress
- More/settings

## Frontend Polish Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- inspect existing Flutter screens for low-risk polish opportunities
- improve consistency of headings, spacing, button labeling, empty states, error states, loading states, and card alignment where useful
- keep the existing design language
- do not redesign the app
- do not add new feature modules

## Frontend Behavior Cleanup Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- inspect refresh behavior after saves and mutations
- fix small inconsistencies if found
- improve basic user feedback where useful
- keep Riverpod flows lifecycle-safe and straightforward
- do not rewrite architecture

## Backend Cleanup Requirements

Work inside:

- `backend`

Requirements:

- inspect current endpoints, services, and repositories for low-risk cleanup opportunities
- improve consistency of responses and error handling where appropriate
- keep endpoints thin
- do not add new business features
- do not add production auth yet

## Documentation Requirements

Requirements:

- update `README.md`, `CODEX_CONTEXT.md`, and `NEXT_TASK.md` so they reflect that the MVP runtime is working and the active phase is post-MVP polish and cleanup
- keep local setup notes practical and concise
- preserve the repository root guardrails and anti-drift rules

## Out Of Scope

Do not add these as part of this phase:

- production auth
- backend login or signup APIs
- barcode scanning
- recipes
- new product modules
- broad architecture rewrites
- unrelated visual redesign work
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- the root guidance files reflect post-MVP polish and cleanup instead of runtime stabilization
- low-risk frontend consistency issues have been cleaned up
- obvious save/refresh inconsistencies have been cleaned up without introducing lifecycle problems
- low-risk backend consistency issues have been cleaned up
- the working MVP is left in a cleaner and more maintainable state
- no new root folder was created
