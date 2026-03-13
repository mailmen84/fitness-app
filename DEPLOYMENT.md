# Deployment Guide

This guide describes the preferred AWS staging shape for the current `fitness-app` architecture.

The repository is a hardened, demo-ready authenticated MVP. The goal here is not full production infrastructure. The goal is the simplest realistic AWS staging environment that one developer can build, run, and demo.

## Preferred AWS Staging Architecture

### Summary

Use this shape first:

- frontend: Flutter web build served as static files from one Amazon Lightsail Linux instance
- backend: FastAPI running on that same Lightsail instance in Docker behind Nginx
- database: one Amazon Lightsail managed PostgreSQL database in the same region
- networking: one public staging hostname pointing at a Lightsail static IP

This is the recommended default because:

- it uses the fewest AWS resources
- it avoids frontend/backend cross-origin complexity by keeping the app same-origin
- it works with the repo as it exists today
- it is easier to understand and recover when one developer owns the whole staging environment

### Why not split the frontend and backend yet?

A split setup is possible later, but it adds more moving parts immediately:

- separate frontend hosting
- explicit cross-origin browser traffic
- more CORS surface area
- more places to debug staged auth issues

For the current MVP, one Lightsail instance plus one Lightsail PostgreSQL database is the cleaner staging path.

## AWS Resource Layout

### Frontend hosting

Host the Flutter web build on the Lightsail instance itself.

Recommended runtime shape:

- build Flutter web locally or in a simple build machine
- copy `apps/mobile_web_flutter/build/web` to the instance
- serve it from Nginx under `/`
- use SPA fallback so routes like `/login` and `/more/profile` return `index.html`

Supporting file already in the repo:

- `staging.nginx.example.conf`

### Backend hosting

Run the backend on the same Lightsail instance in Docker.

Recommended runtime shape:

- use the existing `backend/Dockerfile`
- use `backend/entrypoint.sh` so migrations can run automatically on container start
- publish the backend only to `127.0.0.1:8000`
- let Nginx reverse-proxy `/api/` to that local backend process

Supporting files already in the repo:

- `backend/Dockerfile`
- `backend/entrypoint.sh`
- `backend/.dockerignore`

### Database hosting

Use Amazon Lightsail managed PostgreSQL.

Recommended shape:

- put it in the same AWS region as the Lightsail instance
- create a dedicated staging database
- use the database endpoint from Lightsail for both the app connection string and the Alembic migration connection string
- keep public access as narrow as practical for staging

## Required Environment Variables

These are the key staging values for the backend container.

### Required backend values

- `BACKEND_ENVIRONMENT=staging`
- `BACKEND_HOST=0.0.0.0`
- `BACKEND_PORT=8000`
- `BACKEND_DATABASE_URL=postgresql+asyncpg://USER:PASSWORD@DB_HOST:5432/fitness_app`
- `BACKEND_ALEMBIC_DATABASE_URL=postgresql+psycopg://USER:PASSWORD@DB_HOST:5432/fitness_app`
- `BACKEND_AUTH_SECRET_KEY=<long-random-secret-at-least-32-characters>`
- `BACKEND_DOCS_ENABLED=false`
- `BACKEND_DATABASE_ECHO=false`
- `BACKEND_CORS_ALLOWED_ORIGINS=["https://staging.example.com"]`
- `BACKEND_CORS_ALLOW_CREDENTIALS=true`

### Recommended auth-token values

- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS=43200`
- `BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS=3600`
- `BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS=86400`

### Container-start helper

- `BACKEND_RUN_MIGRATIONS=1`

That variable is used by `backend/entrypoint.sh` so the container runs `alembic upgrade head` before starting Uvicorn.

### Frontend build-time value

Build the Flutter app with:

- `API_BASE_URL=https://staging.example.com`

Because the frontend and backend are served from the same public origin in this staging shape, the Flutter client can call `/api/v1/...` through that single staging host.

## Required CORS, API Base URL, And Auth Settings

### API base URL

Use the public staging origin as the build-time value.

Example:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

### CORS

Even though the app is same-origin in this staging design, keep backend CORS explicit for the public staging URL.

Recommended value:

```text
BACKEND_CORS_ALLOWED_ORIGINS=["https://staging.example.com"]
```

Do not rely on localhost defaults in staging.

### Auth secret

Use a unique staging secret and never reuse the sample development secret from `.env.example`.

Recommended rule:

- generate one long random secret for staging
- keep it outside the repo
- do not share it across environments

## Deployment Steps In Order

### 1. Create AWS resources

Create these first:

- one Amazon Lightsail Linux instance
- one Amazon Lightsail static IP and attach it to the instance
- one Amazon Lightsail managed PostgreSQL database in the same region
- optional: a Lightsail DNS zone or existing DNS record for `staging.example.com`

### 2. Prepare the instance

On the Lightsail instance:

```bash
sudo apt update
sudo apt install -y docker.io nginx git
sudo systemctl enable --now docker nginx
sudo mkdir -p /opt/fitness-app /var/www/fitness-app/web
sudo chown -R $USER:$USER /opt/fitness-app /var/www/fitness-app
```

Then copy or clone the repo to the instance:

```bash
cd /opt
git clone <your-repo-url> fitness-app
```

### 3. Create the staging backend environment file

Create a staging `.env` on the instance, for example at `/opt/fitness-app/.env`.

At minimum include:

```text
BACKEND_ENVIRONMENT=staging
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
BACKEND_DATABASE_URL=postgresql+asyncpg://USER:PASSWORD@DB_HOST:5432/fitness_app
BACKEND_ALEMBIC_DATABASE_URL=postgresql+psycopg://USER:PASSWORD@DB_HOST:5432/fitness_app
BACKEND_AUTH_SECRET_KEY=replace-with-a-long-random-secret
BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS=43200
BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS=3600
BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS=86400
BACKEND_DOCS_ENABLED=false
BACKEND_DATABASE_ECHO=false
BACKEND_CORS_ALLOWED_ORIGINS=["https://staging.example.com"]
BACKEND_CORS_ALLOW_CREDENTIALS=true
BACKEND_RUN_MIGRATIONS=1
```

### 4. Build the Flutter web app for staging

From your local machine or build machine:

```bash
cd apps/mobile_web_flutter
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

Copy the generated web build to the instance:

```bash
rsync -av --delete build/web/ user@staging.example.com:/var/www/fitness-app/web/
```

### 5. Configure Nginx

Use the repo’s example config as a base:

```bash
sudo cp /opt/fitness-app/staging.nginx.example.conf /etc/nginx/sites-available/fitness-app
sudo ln -s /etc/nginx/sites-available/fitness-app /etc/nginx/sites-enabled/fitness-app
sudo nginx -t
sudo systemctl reload nginx
```

Before reloading Nginx:

- replace `staging.example.com` with the real host
- confirm the web root points to `/var/www/fitness-app/web`

This gives you:

- static frontend hosting at `/`
- SPA fallback to `index.html`
- backend reverse proxy from `/api/` to `127.0.0.1:8000`

### 6. Build and run the backend container

On the Lightsail instance:

```bash
cd /opt/fitness-app/backend
docker build -t fitness-app-backend .
docker rm -f fitness-app-backend || true
docker run -d \
  --name fitness-app-backend \
  --restart unless-stopped \
  --env-file /opt/fitness-app/.env \
  -p 127.0.0.1:8000:8000 \
  fitness-app-backend
```

That container will:

- read the backend env vars
- run `alembic upgrade head` if `BACKEND_RUN_MIGRATIONS=1`
- start Uvicorn on port 8000

### 7. Point DNS to the staging instance

Point `staging.example.com` to the Lightsail static IP.

If you are not using a custom domain yet, you can temporarily build the frontend against the instance public URL instead, but a real staging hostname is cleaner.

### 8. Smoke test the deployed app

Verify at minimum:

- welcome screen loads
- signup works
- login after sign-out works
- onboarding completes
- Today meal logging works
- Nutrition loads
- Progress save flows work
- More profile/goals/preferences saves work

## Operational Notes For This Staging Shape

### HTTPS

For a true shared staging environment, add HTTPS before wider demos.

Simple options:

- terminate TLS on the instance with your preferred web-server setup
- or add another AWS layer later if you decide you want managed TLS in front of the instance

This guide keeps TLS automation out of scope because the goal is a low-complexity MVP staging plan, not full production infrastructure.

### Deployment updates

For the first staging setup, the simplest update flow is manual:

1. pull the latest code on the instance
2. rebuild the Flutter web bundle
3. copy the web bundle to the web root
4. rebuild and restart the backend container
5. run a short smoke pass

### Backups and failure tolerance

For staging, at minimum:

- enable Lightsail database backups if available for your selected database plan
- keep a copy of the staging `.env` outside the instance
- keep the Docker and Nginx commands documented for re-provisioning

## What Still Remains Before Real Production Deployment

This AWS staging plan is intentionally simple. It does not yet cover:

- CI/CD pipelines for frontend and backend deployment
- infrastructure-as-code
- automated TLS and domain lifecycle management
- secret-manager integration
- outbound email delivery for password reset or verification
- refresh tokens or server-side session revocation
- observability, alerting, uptime checks, or centralized log shipping
- blue/green deploys, zero-downtime migration workflows, or autoscaling
