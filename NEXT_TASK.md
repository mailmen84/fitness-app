# NEXT_TASK

This file intentionally describes only the active milestone.

Current milestone: runtime verification and stabilization.

## Goal

Make the existing MVP structure more execution-ready and internally consistent without introducing major new product features.

The objective of this milestone is to reduce setup ambiguity, clean up low-risk inconsistencies, and leave the repository in a state where it can be verified more confidently on a real machine.

## Verification Preparation Requirements

Work inside:

- `C:\New folder\fitness-app`

Requirements:

- inspect the current repo for anything likely to block local execution
- check root and backend setup instructions for gaps
- check env and config assumptions
- check whether documented Flutter and backend commands match the current repository shape
- identify obvious missing local setup instructions

## Flutter Stabilization Requirements

Work inside:

- `apps/mobile_web_flutter`

Requirements:

- inspect routing, Riverpod providers, API client seams, form flows, and refresh behavior for obvious inconsistencies
- clean up low-risk issues only
- improve straightforward error messages and edge-case handling where useful
- keep using go_router, Riverpod, shared widgets, and the shared theme
- do not redesign the app
- do not add new product features or new product modules

## Backend Stabilization Requirements

Work inside:

- `backend`

Requirements:

- inspect config, dependencies, Alembic, API router wiring, repository/service seams, and response contracts for obvious inconsistencies
- clean up low-risk issues only
- improve consistency where needed
- keep endpoints thin
- keep the existing dev-only current-user resolution approach for now
- do not add new business features

## Documentation Requirements

Requirements:

- make sure the root `README.md` clearly explains:
  - how to prepare `.env`
  - how to run Docker Compose
  - how to run the backend locally
  - how to run Flutter locally
  - known limitations of the current dev-only auth setup
- make sure `backend/README.md` explains the backend local setup and current route surface accurately
- keep root-path rules and anti-drift rules intact

## Verification Scaffolding Requirements

Requirements:

- improve test or verification scaffolding where useful
- do not invent fake execution results
- if the local toolchain is still unavailable in the Codex environment, state clearly what could not be executed
- prefer honest execution notes over implied pass/fail claims

## Out Of Scope

Do not add these as part of this milestone:

- production auth
- backend login or signup APIs
- barcode scanning
- recipes
- new product modules
- major architecture rewrites
- advanced nutrition or progress features
- unrelated visual redesign work
- a new repository root folder

## Definition Of Done

This milestone is done when all of the following are true:

- the root guidance files reflect that More/settings polish is complete and runtime verification/stabilization is current
- setup and local run documentation is materially clearer and more accurate than before
- obvious low-risk Flutter consistency issues have been cleaned up
- obvious low-risk backend consistency issues have been cleaned up
- verification limits are stated honestly for the current Codex environment
- the repo is better positioned for a real local execution pass
- no new root folder was created
