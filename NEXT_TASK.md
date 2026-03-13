# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: simple AWS staging deployment plan.

## Goal

Prepare a practical, low-complexity AWS staging approach for the current application using a demo mindset rather than full production infrastructure.

## Current Baseline

The app is now a hardened, demo-ready authenticated MVP across:

- Today
- Add
- Nutrition
- Progress
- More/settings

Real auth is already in place and hardened beyond the original MVP state. This phase is about defining the easiest realistic AWS staging shape for one developer.

## AWS Staging Requirements

Requirements:

- review the current repo structure and deployment docs
- propose the simplest realistic AWS staging architecture for the exact app
- prefer a Lightsail-oriented setup when that keeps complexity down
- document where the frontend, backend, and database should live
- document the required environment variables, build steps, and deploy steps

## Runtime And Config Requirements

Requirements:

- keep dev, local, and staging responsibilities clear
- document required `API_BASE_URL`, CORS, and auth-secret settings for staging
- avoid breaking current local development flow
- add only small supporting deployment files when they are clearly useful

## Out Of Scope

Do not add these as part of this phase:

- new product modules
- barcode scanning
- recipes
- broad architecture refactors
- full production infrastructure automation
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- the repo documents one clear AWS staging path for this MVP
- the frontend, backend, and database hosting choices are explicit
- required env vars and deploy steps are documented in order
- any supporting deployment files stay small and practical
- the project is easier for one developer to deploy as a staging/demo environment
- no new root folder was created
