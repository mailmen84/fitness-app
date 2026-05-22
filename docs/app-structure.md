# App structure

End-to-end architecture of the fitness app: backend (FastAPI), mobile client
(Flutter), infrastructure (Proxmox homelab + Cloudflare Tunnel), and data
pipelines. This is meant as a quick map of the codebase and the deploy
topology; it stays high level on purpose so it does not rot every time a file
moves.

## High-level topology

```
              ┌──────────────────────────┐
              │  Phone / Browser         │
              │  Flutter APK or web      │
              └────────────┬─────────────┘
                           │ HTTPS
                           ▼
              ┌──────────────────────────┐
              │  Cloudflare              │
              │  fitness.nodecrafts.org  │
              └────────────┬─────────────┘
                           │ cloudflared tunnel
                           ▼
        ┌──────────────────────────────────────┐
        │  app-vm  192.168.20.50               │
        │  Docker Compose (prod)               │
        │   - backend (FastAPI, uvicorn :8000) │
        │   - cloudflared                      │
        │   - imports/ volume (OFF CSV)        │
        └────────────┬─────────────────────────┘
                     │ asyncpg / SQLAlchemy
                     ▼
        ┌──────────────────────────────────────┐
        │  db-vm  192.168.20.51                │
        │  Postgres 16 (bare metal)            │
        │   - pg_trgm + GIN indexes on foods   │
        │   - 244 GB LVM volume                │
        └──────────────────────────────────────┘
```

External data source: OpenFoodFacts (CSV dump + REST API for live barcode
lookup).

## Repository layout

```
fitness-app/
├── apps/
│   └── mobile_web_flutter/        # Flutter app (Android APK + web build)
├── backend/                       # FastAPI service
│   ├── app/                       # Application code
│   ├── alembic/                   # DB migrations
│   ├── scripts/                   # One-off / data scripts (import, seed)
│   ├── tests/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docs/
│   ├── homelab-deploy.md          # How to deploy onto the homelab
│   └── app-structure.md           # ← this file
├── docker-compose.yml             # Local dev (Postgres only)
├── DEPLOYMENT.md
├── README.md
└── .env.example
```

## Backend

FastAPI + SQLAlchemy 2 (async) + Alembic + Pydantic v2. Layout follows a
loose Domain Driven Design split — domain models and pure logic do not import
from infrastructure, infrastructure does not import from the API layer.

### Layers

```
backend/app/
├── main.py                        # FastAPI factory, CORS, lifespan, router
├── api/
│   └── v1/
│       ├── endpoints/             # HTTP handlers (one file per domain)
│       │   ├── auth.py            # /auth/signup, /auth/login, refresh
│       │   ├── foods.py           # /foods, /foods/search, /foods/barcode/{code}
│       │   ├── meals.py           # /meals, /meals/entries
│       │   ├── nutrition.py       # daily totals, macros
│       │   ├── goals.py
│       │   ├── progress.py
│       │   ├── health.py
│       │   ├── preferences.py
│       │   ├── users.py
│       │   └── system.py          # /healthz, /readyz
│       └── (router wiring)
├── application/
│   └── services/                  # Use-case orchestration, transaction scope
├── domain/                        # Pure domain models + ORM tables
│   ├── auth/                      # User credentials, refresh tokens
│   ├── users/                     # User profile
│   ├── foods/                     # Food, FoodNutrient
│   ├── meals/                     # Meal, MealEntry (snapshots of food)
│   ├── nutrition/                 # Daily aggregates
│   ├── goals/                     # Targets (kcal, macros)
│   ├── progress/                  # Body metrics over time
│   ├── health/                    # System health probes
│   ├── preferences/               # Units, locale
│   ├── system/                    # System-level entities
│   └── shared/                    # Base mixins (UUID PK, timestamps)
├── infrastructure/
│   ├── persistence/
│   │   ├── (session, engine, base)
│   │   └── repositories/          # SQLAlchemy queries, e.g. foods_repository.py
│   └── external/
│       └── openfoodfacts_client.py # Live barcode lookup over HTTPS
└── core/                          # Settings, security, deps, logging
```

### Request flow

```
HTTP request
   → api/v1/endpoints/foods.py  (validate, auth, call service)
   → application/services/...   (transaction boundary, business rules)
   → infrastructure/persistence/repositories/foods_repository.py
   → SQLAlchemy AsyncSession → Postgres
```

### Foods search

`foods_repository.search_by_name` uses Postgres `pg_trgm`:

- ≥ 3 chars: GIN trigram index on `foods.name` and `foods.brand`,
  ordered by `similarity(name, :q) DESC` with a tiered `CASE` rank
  (exact > prefix > contains > trigram fuzzy).
- < 3 chars: falls back to `ILIKE 'q%'` to keep results bounded.

### Database schema (core tables)

```
users(id uuid PK, email, password_hash, created_at, …)
foods(id uuid PK, name, brand, source, barcode UNIQUE NULL,
      default_serving_amount NUMERIC(10,2), default_serving_unit, …)
food_nutrients(id uuid PK, food_id uuid FK → foods.id ON DELETE CASCADE,
               nutrient_code VARCHAR(64) INDEX,   -- 'calories','protein',…
               amount NUMERIC(12,4),
               unit VARCHAR(16))
meals(id uuid PK, user_id FK, eaten_at, meal_type, …)
meal_entries(id uuid PK, meal_id FK, food_id FK,
             snapshot fields for kcal/macros, amount, unit)
goals(id uuid PK, user_id FK, kcal_target, protein/carbs/fat targets, …)
auth_refresh_tokens(id uuid PK, user_id FK, token_hash, expires_at, …)
```

Sources tracked in `foods.source`: `openfoodfacts`, `seed_pl`,
`development_seed`, and user-created entries.

### Migrations

`backend/alembic/versions/`:

| Revision         | Purpose                                            |
| ---------------- | -------------------------------------------------- |
| `20260310_0001`  | Initial foundation (users, auth, foods, meals)     |
| `20260310_0002`  | Meal entry snapshots                                |
| `20260312_0003`  | Auth security basics (refresh tokens)               |
| `20260518_0004`  | `foods.barcode` column + unique index               |
| `20260518_0005`  | Full macros + per-user nutrient targets             |
| `20260522_0006`  | `pg_trgm` extension + GIN indexes on foods         |

Migrations run automatically on container start when
`BACKEND_RUN_MIGRATIONS=1` (`entrypoint.sh` → `alembic upgrade head` →
`uvicorn`).

### Scripts (`backend/scripts/`)

- `import_off.py` — streams the gzipped OpenFoodFacts CSV, parses rows,
  caps absurd nutrient values (> 100 000) to `NULL`, batches `INSERT … ON
  CONFLICT (barcode) DO NOTHING` 5 000 rows at a time. Idempotent.
- `seed_polish_basics.py` — ~220 generic Polish foods (ziemniak, ryż, pierś
  z kurczaka, jajko, …) with full macros. Safe to re-run.
- `foods_stats.py` — quick counters: rows by source, with/without macros,
  table size.

Scripts are baked into the image (`COPY scripts ./scripts` in the
Dockerfile) and invoked with `docker compose exec backend python -m
scripts.import_off /imports/en.openfoodfacts.org.products.csv.gz`.

### Tests

- `backend/tests/scripts/test_import_off_parser.py` — 25 unit tests for the
  CSV parser helpers (numeric coercion, value capping, multilingual name
  picking, edge cases).
- Domain/service tests under `backend/tests/`.

## Mobile (Flutter)

Located in `apps/mobile_web_flutter/`. Single codebase ships an Android APK
and a web build. Riverpod for state, GoRouter for navigation.

### Feature structure

Each feature follows the same shape:

```
features/<feature>/
├── application/      # Riverpod controllers / providers
├── domain/           # Plain Dart models
├── infrastructure/   # API clients, mapping JSON ↔ domain
└── presentation/     # Screens + widgets
```

Features:

```
features/
├── auth/             # Signup, login, forgot password
├── onboarding/       # Goal, stats, activity, target
├── app_shell/        # Bottom nav scaffold
├── today/            # Daily dashboard
├── nutrition/        # Macro breakdown, history
├── add/              # Add food: hub, search, barcode scanner, scan review
├── progress/         # Weight & metric tracking
├── more/             # Settings, sign out
├── ped/              # (placeholder feature)
└── shared/           # Cross-feature widgets / providers
```

### Core

```
core/
├── config/           # Environment, base URL
├── network/          # Dio client, interceptors (auth, refresh, retry)
├── router/           # GoRouter setup, AppRoutePaths
├── theme/            # AppTheme + design tokens
├── presentation/widgets/  # Reusable: AppPrimaryButton, AppStandardCard, …
├── serialization/    # JSON helpers
└── validation/       # Form validators
```

### Barcode scanner (`features/add/presentation/barcode_scanner_screen.dart`)

Uses the `mobile_scanner` package with:

- `DetectionSpeed.noDuplicates`
- `detectionTimeoutMs: 800` cooldown so the user has time to aim before
  the next detection attempt fires
- Restricted formats: EAN-13, EAN-8, UPC-A, UPC-E, Code128, Code39
- Manual barcode entry fallback

Flow on hit:

```
onDetect → controller.stop → barcodeFlowController.lookup(code)
  → BarcodeLookupKind.foundLocal      → /add/food/:id (local food detail)
  → BarcodeLookupKind.foundOpenFoodFacts → /add/scan-review/:code
  → BarcodeLookupKind.notFound        → /add/scan-review/:code (create new)
  → BarcodeLookupKind.error           → re-start scanner, show error block
```

`barcodeFlowController.lookup` first hits the backend `/foods/barcode/{code}`
which checks the local DB; if missing the backend falls back to the
OpenFoodFacts REST client.

### Android release

- Signing config in `apps/mobile_web_flutter/android/app/build.gradle`
- Upload keystore: `android/app/upload-keystore.jks` (not committed)
- `android/key.properties` is git-ignored, holds keystore password / alias
- Build: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- Cheatsheet: `apps/mobile_web_flutter/android/RELEASE.md`

## Infrastructure (homelab)

Detailed in `docs/homelab-deploy.md`. Summary:

### Hosts

| Host    | IP             | Role                                             |
| ------- | -------------- | ------------------------------------------------ |
| app-vm  | 192.168.20.50  | Docker Compose: backend + cloudflared            |
| db-vm   | 192.168.20.51  | Postgres 16 (native, not in Docker)              |

Both VMs run on Proxmox. db-vm has been LVM-extended to ~244 GB to host
the full OFF dataset; app-vm has ~123 GB free.

### Networking

- Phone / browser → Cloudflare → `cloudflared` on app-vm → `127.0.0.1:8000`
  (backend container).
- Tunnel hostname: `fitness.nodecrafts.org`.
- CORS on the backend allows only the public hostname; local browsers on
  arbitrary `localhost:PORT` are rejected by design (use the APK, or add the
  origin in `.env`).

### Production compose (on app-vm)

`~/apps/fitness-app/docker-compose.prod.yml`:

- `backend` — built from `backend/Dockerfile`, runs `entrypoint.sh`
- `cloudflared` — uses tunnel credentials from a host-mounted secret
- `imports/` volume mounted read-only at `/imports` inside the backend
  container, holds the OFF CSV dump

### Deploy workflow

`~/apps/fitness-app/deploy.sh` on app-vm:

```bash
git pull
docker compose -f docker-compose.prod.yml build --no-cache backend
docker compose -f docker-compose.prod.yml up -d
docker image prune -f
```

Migrations run automatically on container start (alembic upgrade head).

## Data pipelines

### Live barcode lookup

```
Phone scans barcode
   → POST /foods/barcode/{code} on backend
   → foods_repository.find_by_barcode (local DB hit?)
        → yes → return cached food row + nutrients
        → no  → infrastructure/external/openfoodfacts_client.py
                  → HTTPS GET world.openfoodfacts.org/api/v2/product/{code}
                  → parse, persist into foods + food_nutrients
                  → return
```

### Bulk OFF import

```
Download dump  → app-vm:~/apps/fitness-app/imports/en.openfoodfacts.org.products.csv.gz
docker compose exec backend python -m scripts.import_off /imports/<file>.csv.gz
   → stream .gz line-by-line (no full decompress)
   → parse each row, cap absurd values, drop blanks
   → batch 5 000 rows, INSERT … ON CONFLICT (barcode) DO NOTHING
   → log progress every batch
```

Idempotent — re-runs skip existing barcodes. After import, optional
cleanup query removes OFF rows that have no usable calories so search
results stay relevant.

### Polish seed

```
docker compose exec backend python -m scripts.seed_polish_basics
```

Inserts ~220 hand-curated entries with `source='seed_pl'`. Re-runs are
no-ops.

## Local development

```bash
# Postgres only
docker compose up -d postgres

# Backend
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e .
alembic upgrade head
uvicorn app.main:app --reload

# Flutter
cd apps/mobile_web_flutter
flutter pub get
flutter run -d chrome              # web
flutter run -d <device-id>         # phone
```

Environment template: `.env.example` (DB URL, JWT secret, CORS origins,
OpenFoodFacts client toggles).

## Where things live (quick lookup)

| I want to…                       | Look here                                                          |
| -------------------------------- | ------------------------------------------------------------------ |
| Add a new HTTP endpoint          | `backend/app/api/v1/endpoints/<domain>.py`                         |
| Add a new DB column              | New file in `backend/alembic/versions/`                            |
| Change food search ranking       | `backend/app/infrastructure/persistence/repositories/foods_repository.py` |
| Tune the barcode scanner UX      | `apps/mobile_web_flutter/lib/features/add/presentation/barcode_scanner_screen.dart` |
| Re-run the OFF import            | `backend/scripts/import_off.py`                                    |
| Deploy a backend change          | `deploy.sh` on app-vm                                              |
| Sign / build a release APK       | `apps/mobile_web_flutter/android/RELEASE.md`                       |
| Recover the homelab setup        | `docs/homelab-deploy.md`                                           |
