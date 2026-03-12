# NEXT_TASK

This file intentionally describes only the active phase.

Current phase: auth hardening and security basics.

## Goal

Strengthen the working authentication system and security foundations without adding unrelated product features, broad rewrites, or full production infrastructure.

## Current Baseline

The app is now a demo-ready authenticated MVP across:

- Today
- Add
- Nutrition
- Progress
- More/settings

Real auth is already in place. This phase is about making that auth more robust, more predictable, and easier to extend safely.

## Auth Hardening Requirements

Requirements:

- review the current bearer-token auth flow and keep it lifecycle-safe
- improve low-risk security foundations where practical
- prepare the session model for future refresh-token or revocation work without fully implementing that whole system yet
- improve auth validation and error handling consistency

## Account Security Foundations

Requirements:

- keep password-reset support practical and minimal
- add or preserve clean groundwork for email verification
- keep developer-friendly local behavior where appropriate
- avoid adding social auth or unrelated account features

## Backend And Frontend Requirements

Requirements:

- keep backend endpoints thin and move logic into services and repositories
- keep frontend auth UX minimal and aligned with existing screens
- keep route guards and session restore predictable
- improve low-risk auth/security documentation and config clarity where useful

## Documentation Requirements

Requirements:

- keep `README.md`, `CODEX_CONTEXT.md`, and `NEXT_TASK.md` aligned with this active phase
- document the strengthened auth flow, current reset/verification foundations, and current limits
- keep local setup notes practical and concise
- point the likely next milestone toward deployment readiness and production infrastructure planning

## Out Of Scope

Do not add these as part of this phase:

- new product modules
- barcode scanning
- recipes
- social auth
- full production deployment infrastructure
- broad architecture refactors
- a new repository root folder

## Definition Of Done

This phase is done when all of the following are true:

- bearer-token auth is in a stronger, more predictable state than before
- password reset and email verification groundwork are cleaner and better documented
- low-risk auth/session lifecycle issues have been reduced rather than expanded
- auth-related verification confidence is better than at the start of the phase
- the repo docs clearly reflect the new auth-hardening milestone and the next likely deployment-readiness phase
- no new root folder was created
