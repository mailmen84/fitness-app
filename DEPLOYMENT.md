# Deployment Guide

This guide describes the current secondary deployment path for the `fitness-app` repository.

Important direction note:

- the primary product target is now an installable phone app, with Android first and iPhone-ready architecture second
- web deployment is still useful for demos, QA, admin access, and secondary access paths
- this document remains valid, but it no longer defines the primary product goal

The repository is a hardened authenticated MVP. The web staging goal here is still low-complexity support for demos and secondary access, not a return to a web-first roadmap.

## Secondary AWS Staging Architecture

### Summary

If a lightweight staging website is still needed, use this shape first:

- frontend: Flutter web build served as static files from one Amazon Lightsail Linux instance
- backend: FastAPI running on that same Lightsail instance in Docker behind Nginx
- database: one Amazon Lightsail managed PostgreSQL database in the same region
- networking: one public staging hostname pointing at a Lightsail static IP

This remains the recommended secondary web staging shape because:

- it uses the fewest AWS resources
- it avoids frontend/backend cross-origin complexity by keeping the staged web app same-origin
- it works with the repo as it exists today
- it is easier to understand and recover when one developer owns the whole staging environment

### Why this is now secondary

This setup is still useful, but it is no longer the main product-delivery goal.

The main product path is now:

- Android packaging and install readiness first
- iPhone-ready packaging and polish second
- hosted web access only after that as a supporting path

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
- `BACKEND_RUN_MIGRATIONS=1`

### Recommended auth-token values

- `BACKEND_AUTH_ACCESS_TOKEN_EXPIRE_SECONDS=43200`
- `BACKEND_AUTH_PASSWORD_RESET_TOKEN_EXPIRE_SECONDS=3600`
- `BACKEND_AUTH_EMAIL_VERIFICATION_TOKEN_EXPIRE_SECONDS=86400`

### Frontend build-time value

Build the Flutter web app with:

- `API_BASE_URL=https://staging.example.com`

Because the staged frontend and backend are served from the same public origin in this web-staging shape, the Flutter client can call `/api/v1/...` through that single staging host.

## Required CORS, API Base URL, And Auth Settings

### API base URL

Use the public staging origin as the build-time value.

Example:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://staging.example.com
```

### CORS

Even though the staged web app is same-origin in this design, keep backend CORS explicit for the public staging URL.

Recommended value:

```text
BACKEND_CORS_ALLOWED_ORIGINS=["https://staging.example.com"]
```

### Auth secret

Use a unique staging secret and never reuse the sample development secret from `.env.example`.

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

### 7. Point DNS to the staging instance

Point `staging.example.com` to the Lightsail static IP.

### 8. Smoke test the staged web app

Verify at minimum:

- welcome screen loads
- signup works
- login after sign-out works
- onboarding completes
- Today meal logging works
- Nutrition loads
- Progress save flows work
- More profile/goals/preferences saves work

## What Still Remains Before Real Production Deployment

This secondary web staging plan is intentionally simple. It does not yet cover:

- CI/CD pipelines for frontend and backend deployment
- infrastructure-as-code
- automated TLS and domain lifecycle management
- secret-manager integration
- outbound email delivery for password reset or verification
- refresh tokens or server-side session revocation
- observability, alerting, uptime checks, or centralized log shipping
- blue/green deploys, zero-downtime migration workflows, or autoscaling

It also does not replace the new primary milestone, which is mobile-native readiness and phone packaging.
