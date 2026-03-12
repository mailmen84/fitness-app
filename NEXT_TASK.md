# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: deployment and demo readiness.

## Goal

Prepare the authenticated working MVP so it is easier to run, demonstrate, and maintain without adding major new product features.

## Current Baseline

The app now has an authenticated working MVP across:

- Today
- Add
- Nutrition
- Progress
- More/settings

Real auth is already in place. This phase is about making the repo and local run flow cleaner for demos and handoff.

## Environment And Config Requirements

Work inside the existing repository root.

Requirements:

- review backend and frontend config usage for clarity and consistency
- remove stale or misleading env/config guidance
- avoid fragile hard-coded assumptions where low-risk cleanup is possible
- keep local setup practical for another developer or tester

## Documentation And Run-Flow Requirements

Requirements:

- improve `README.md` and `backend/README.md`
- keep `CODEX_CONTEXT.md` and `NEXT_TASK.md` aligned with the active phase
- make Docker, backend, and Flutter startup steps easier to follow
- document the current auth flow, token/session behavior, and known limits
- keep docs practical and concise

## Demo And Stability Requirements

Requirements:

- review demo data behavior and keep it lightweight and predictable
- improve low-risk runtime wording, logging, and setup guidance where useful
- do not rewrite architecture
- do not change major product behavior unless needed for readiness

## Out Of Scope

Do not add these as part of this phase:

- new product modules
- barcode scanning
- recipes
- production deployment infrastructure beyond documentation or setup notes
- broad architecture refactors
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- env and config usage is clearer and more consistent for local runs
- startup steps for Docker, backend, and Flutter are easier to follow
- the current auth flow and its local limits are clearly documented
- demo data behavior is understandable for local demos
- the project is left in a cleaner state for a future true deployment and production-readiness pass
- no new root folder was created
