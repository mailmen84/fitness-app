# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: stability and verification pass.

## Goal

Improve the existing polished MVP so it behaves more predictably, initializes more safely, and carries stronger verification confidence without introducing major new product features.

## Current Baseline

The app now has a polished working MVP runtime across:

- Today
- Add
- Nutrition
- Progress
- More/settings

## Frontend Stability Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- inspect form screens that still seed controller values during the first rendered data pass
- replace fragile initialization patterns with safer explicit initialization where appropriate
- keep Riverpod flows lifecycle-safe
- do not rewrite architecture
- do not add new product features

## Frontend Verification Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- review the current Flutter widget test coverage
- improve low-risk widget or screen-level verification where useful
- keep tests practical and focused on currently working MVP behavior

## Backend Verification Requirements

Work inside:

- `backend`

Requirements:

- review backend test coverage and low-risk consistency edges
- improve thin endpoint consistency or focused contract tests where useful
- keep endpoints thin
- do not add new business modules
- do not introduce production auth

## Wording Cleanup Requirements

Requirements:

- remove obvious `foundation`, `scaffold`, or `preview` wording where it is no longer accurate for the current MVP
- keep copy practical and minimal
- preserve intentionally accurate dev-only auth wording until real auth exists

## Documentation Requirements

Requirements:

- update `README.md`, `CODEX_CONTEXT.md`, and `NEXT_TASK.md` so they reflect the stability and verification pass
- make it clear that the MVP runtime is working and polished
- note that the next likely milestone after this phase is real authentication or deployment/demo readiness
- keep setup notes practical and concise
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

- fragile first-render form seeding has been replaced where needed in the working MVP flows
- focused frontend and backend verification coverage is stronger than before
- obvious outdated MVP wording has been cleaned up where appropriate
- the root guidance files reflect the stability and verification pass
- the project is left in a more predictable and verifiable MVP state
- no new root folder was created
