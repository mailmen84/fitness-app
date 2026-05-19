# Fitness App — Deploy do homelaba (Proxmox + Cloudflare Tunnel)

Krok po kroku jak postawić backend na dwóch VM-kach w Proxmoxie i wystawić go pod
`https://fitness.nodecrafts.org` przez Cloudflare Tunnel. Każde polecenie ma być
do skopiowania bez modyfikacji — wszystkie konkretne IP, nazwy hostów i ścieżki
są wpisane na sztywno. Jeżeli czegoś u Ciebie nie ma na liście — daj znać przed
wykonaniem, nie zgaduj.

Skróty używane w guide:

- **db-vm** — VM z PostgreSQL, IP `192.168.20.51`, hostname `fitness-db`
- **app-vm** — VM z backendem + Cloudflare Tunnel, IP `192.168.20.50`,
  hostname `fitness-app`
- **laptop** — Twój PC, z którego buildujesz APK i robisz git push

---

## Sekcja 0 — Co przygotujesz przed startem

Lista rzeczy do zebrania (zajmie 5 minut). Trzymaj je w menedżerze haseł albo
notatce — będą potrzebne w kolejnych sekcjach.

1. **Hasło PostgreSQL** dla użytkownika aplikacji. Wygeneruj losowe, np. tak na
   laptopie w PowerShellu:

   ```powershell
   -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
   ```

   Zapisz wynik jako **`POSTGRES_PASSWORD`**.

2. **Sekret JWT dla backendu** — drugi losowy ciąg (32+ znaków):

   ```powershell
   -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | % {[char]$_})
   ```

   Zapisz jako **`BACKEND_AUTH_SECRET_KEY`**.

3. **Cloudflare** — zaloguj się na [dash.cloudflare.com](https://dash.cloudflare.com),
   upewnij się że domena `nodecrafts.org` jest w stanie *Active* (zielona kropka).
   Notatka: będziemy używać produktu **Zero Trust → Networks → Tunnels**, nie
   trzeba kupować Access ani niczego dodatkowo.

4. **Klucz SSH** z laptopa do obu VM-ek. Jeśli nie masz, na laptopie w
   PowerShellu:

   ```powershell
   ssh-keygen -t ed25519 -C "homelab"
   ```

   Domyślne ścieżki ENTER, hasło ENTER (puste). Klucz publiczny wylądował w
   `C:\Users\<Ty>\.ssh\id_ed25519.pub`. Zaraz wgramy go do VM-ek.

---

## Sekcja 1 — Sieć Proxmox i IP VM-ek

Zakładam, że VM-ki już są utworzone z Ubuntu Server 24.04 (minimal). Jeśli nie:
w Proxmoxie **Create VM** → Ubuntu 24.04 ISO → 2 CPU / 4 GB RAM / 20 GB dysku
(dla app-vm), 2 CPU / 8 GB RAM / 40 GB (dla db-vm). Sieć: vmbr0, VLAN 20.

### 1.1 Ustaw stałe IP na obu VM-kach

Zaloguj się na **db-vm** (przez konsolę Proxmox):

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Wklej (zachowaj wcięcia, YAML jest na nie wrażliwy):

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses: [192.168.20.51/24]
      routes:
        - to: default
          via: 192.168.20.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

Jeśli interfejs nazywa się inaczej niż `ens18`, sprawdź przez `ip link` i podstaw.
Zapisz (Ctrl+O, Enter, Ctrl+X) i zaaplikuj:

```bash
sudo netplan apply
ip addr show ens18
```

Powinieneś zobaczyć `inet 192.168.20.51/24`. Powtórz to samo na **app-vm** z
adresem `192.168.20.50`.

### 1.2 Hostnames

Na **db-vm**:

```bash
sudo hostnamectl set-hostname fitness-db
```

Na **app-vm**:

```bash
sudo hostnamectl set-hostname fitness-app
```

### 1.3 SSH z laptopa

Wróć na laptopa i wgraj klucz publiczny do obu VM-ek (jeden raz, podasz hasło
sudo użytkownika):

```powershell
ssh-copy-id przemek@192.168.20.50
ssh-copy-id przemek@192.168.20.51
```

(podstaw swoją nazwę użytkownika Ubuntu). Jak `ssh-copy-id` nie działa na
Windowsie, alternatywnie:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh przemek@192.168.20.50 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Sprawdź:

```powershell
ssh przemek@192.168.20.50
ssh przemek@192.168.20.51
```

Każda powinna wpuścić bez hasła.

### 1.4 Update systemu (oba VM)

Na **każdej** VM zaloguj się i odpal:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates gnupg git ufw
```

Krótki firewall — domyślnie tylko SSH:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw --force enable
```

Na app-vm dodatkowo otworzymy port 5432 jako klienta (Docker sam to załatwi,
nic nie trzeba ruszać). Na db-vm zaraz dorzucimy regułę dla 5432 tylko z
app-vm.

---

## Sekcja 2 — db-vm: PostgreSQL

### 2.1 Instalacja Postgres 16

Zaloguj się na **db-vm** (`ssh przemek@192.168.20.51`) i:

```bash
sudo apt install -y postgresql-16
```

Sprawdź wersję:

```bash
psql --version
```

Powinno wypisać `psql (PostgreSQL) 16.x`.

### 2.2 Utwórz bazę i użytkownika

```bash
sudo -u postgres psql
```

Wpadłeś do shella psql. Wklej kolejno (podstaw swoje `POSTGRES_PASSWORD` z
sekcji 0 zamiast `WSTAW_HASLO_TUTAJ`):

```sql
CREATE USER fitness_user WITH PASSWORD 'WSTAW_HASLO_TUTAJ';
CREATE DATABASE fitness_app OWNER fitness_user;
GRANT ALL PRIVILEGES ON DATABASE fitness_app TO fitness_user;
\q
```

### 2.3 Pozwól nasłuchiwać na sieci wewnętrznej

Postgres domyślnie słucha tylko `localhost`. Trzeba wystawić go na IP db-vm
i dopuścić tylko app-vm.

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Znajdź linię `#listen_addresses = 'localhost'`, odkomentuj i zmień na:

```
listen_addresses = '192.168.20.51'
```

Zapisz. Następnie:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Na samym dole, **przed** dowolnymi liniami `host all all 0.0.0.0/0`, dodaj:

```
host    fitness_app    fitness_user    192.168.20.50/32    scram-sha-256
```

To dopuszcza tylko app-vm do bazy `fitness_app` jako `fitness_user`, z hasłem.
Zapisz, zrestartuj Postgresa:

```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql --no-pager
```

Status powinien być `active (running)`.

### 2.4 Firewall db-vm

Dopuść 5432 tylko z app-vm:

```bash
sudo ufw allow from 192.168.20.50 to any port 5432 proto tcp
sudo ufw status
```

### 2.5 Test połączenia z app-vm (zrobimy w sekcji 3, gdy app-vm będzie gotowa)

---

## Sekcja 3 — app-vm: Docker + repo + .env

### 3.1 Zainstaluj Dockera

Zaloguj się na **app-vm** (`ssh przemek@192.168.20.50`):

```bash
# Oficjalna procedura Dockera dla Ubuntu
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Dodaj swojego usera do grupy `docker` (żeby nie musieć `sudo` przy każdej
komendzie):

```bash
sudo usermod -aG docker $USER
```

Wyloguj się (`exit`) i zaloguj ponownie. Sprawdź:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

`hello-world` powinno wypisać "Hello from Docker!" i wrócić.

### 3.2 Sklonuj repo

```bash
mkdir -p ~/apps
cd ~/apps
git clone https://github.com/mailmen84/fitness-app.git
cd fitness-app
```

### 3.3 Utwórz `.env` dla produkcji

W katalogu `~/apps/fitness-app/`:

```bash
nano .env
```

Wklej i podstaw oba sekrety z sekcji 0:

```env
BACKEND_ENVIRONMENT=production
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
BACKEND_DOCS_ENABLED=false
BACKEND_RUN_MIGRATIONS=1

BACKEND_DATABASE_URL=postgresql+asyncpg://fitness_user:WSTAW_POSTGRES_PASSWORD@192.168.20.51:5432/fitness_app

BACKEND_AUTH_SECRET_KEY=WSTAW_BACKEND_AUTH_SECRET_KEY

BACKEND_CORS_ALLOWED_ORIGINS=["https://fitness.nodecrafts.org"]
```

Zapisz. Następnie zabezpiecz plik:

```bash
chmod 600 .env
```

Nikt poza Tobą nie powinien móc go otworzyć.

### 3.4 Test połączenia do db-vm

Sprawdź czy app-vm dosięgnie Postgresa na db-vm:

```bash
sudo apt install -y postgresql-client
PGPASSWORD='WSTAW_POSTGRES_PASSWORD' psql -h 192.168.20.51 -U fitness_user -d fitness_app -c "SELECT 1;"
```

Powinno zwrócić `1`. Jeśli `connection refused` → wróć do sekcji 2.3 i sprawdź
`listen_addresses` + restart Postgresa. Jeśli `password authentication failed` →
sprawdź hasło. Jeśli `no pg_hba.conf entry` → sekcja 2.3 reguła w `pg_hba.conf`.

---

## Sekcja 4 — Backend jako Docker container

W repo jest już `backend/Dockerfile` i `docker-compose.yml`, ale ten compose
zawiera tylko Postgres (do lokalnej dev pracy). Dla produkcji potrzebujemy
osobnego pliku, który puszcza **sam backend** (bo Postgres siedzi na db-vm).

### 4.1 Stwórz `docker-compose.prod.yml`

Na **app-vm** w katalogu repo:

```bash
nano docker-compose.prod.yml
```

Wklej:

```yaml
services:
  backend:
    build:
      context: ./backend
    image: fitness-app-backend:latest
    container_name: fitness-app-backend
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "127.0.0.1:8000:8000"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/docs' if False else 'http://localhost:8000/api/v1/health', timeout=3)"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s
```

Zapisz. Uwaga: `ports: 127.0.0.1:8000:8000` powoduje, że backend słucha tylko
na localhost app-vm. Wystawi go na świat Cloudflare Tunnel, nie router.

### 4.2 Build i start

```bash
cd ~/apps/fitness-app
docker compose -f docker-compose.prod.yml up -d --build
```

Pierwszy build potrwa 1–3 minuty (instalacja Pythona, dependencies, alembic).

Sprawdź czy żyje:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

Spodziewane logi:

```
INFO  [alembic.runtime.migration] Running upgrade ... -> 20260518_0005
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

Wciśnij Ctrl+C żeby wyjść z `logs -f` (kontener dalej działa).

Test lokalny na app-vm:

```bash
curl -i http://127.0.0.1:8000/api/v1/health
```

Powinno wrócić `200 OK` z JSON. Jeśli endpoint health nie istnieje, sprawdź
przez `/docs` (i tymczasowo ustaw `BACKEND_DOCS_ENABLED=true` w `.env` +
`docker compose ... restart backend`).

---

## Sekcja 5 — Cloudflare Tunnel → fitness.nodecrafts.org

Cloudflare Tunnel wystawi `https://fitness.nodecrafts.org` z internetu do
backendu na app-vm. **Nie otwieramy żadnego portu na routerze.**

### 5.1 Stwórz tunel w panelu Cloudflare

1. Wejdź na [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. **Networks → Tunnels → Create a tunnel**
3. Connector type: **Cloudflared**, kliknij dalej.
4. Tunnel name: `fitness-homelab`. Save tunnel.
5. Na następnym ekranie wybierz **Debian/Linux x86_64** i skopiuj wyświetloną
   komendę instalacyjną. Wygląda mniej więcej tak (Twoja będzie miała inny
   token):

   ```bash
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
   && sudo dpkg -i cloudflared.deb \
   && sudo cloudflared service install eyJhIjoi...DLUGI_TOKEN...
   ```

6. **Wklej i uruchom tę komendę na app-vm**. Po chwili w panelu Cloudflare
   pojawi się connector ze statusem *Healthy*.

7. Kliknij **Next**. Teraz konfiguracja public hostname:

   - **Subdomain:** `fitness`
   - **Domain:** `nodecrafts.org`
   - **Service Type:** `HTTP`
   - **URL:** `localhost:8000`

   **Save tunnel**.

### 5.2 Sprawdź DNS i działanie

Cloudflare automatycznie doda rekord CNAME dla `fitness.nodecrafts.org` →
`<tunnel-id>.cfargotunnel.com`. Po ~30 sekundach:

```bash
curl -i https://fitness.nodecrafts.org/api/v1/health
```

Powinno zwrócić ten sam JSON co lokalne `127.0.0.1:8000`. Jeśli `502 Bad Gateway`
→ kontener backendu nie działa, sprawdź `docker compose ... logs backend`. Jeśli
`530` → tunel jeszcze się nie podpiął, zaczekaj minutę.

### 5.3 Auto-start cloudflared

Instalator z kroku 5.1 już zarejestrował systemd unit. Sprawdź:

```bash
sudo systemctl status cloudflared
```

Powinno być `active (running)`. Jeśli nie:

```bash
sudo systemctl enable --now cloudflared
```

Po restarcie app-vm cloudflared wstaje automatycznie.

---

## Sekcja 6 — Skrypt deploy + workflow aktualizacji

Każda kolejna zmiana w kodzie ma trafiać na produkcję jedną komendą.

### 6.1 Skrypt `deploy.sh` na app-vm

```bash
nano ~/apps/fitness-app/deploy.sh
```

Wklej:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/apps/fitness-app"
cd "$REPO_DIR"

echo "==> Pulling latest changes from main..."
git fetch origin main
git reset --hard origin/main

echo "==> Rebuilding backend image..."
docker compose -f docker-compose.prod.yml build backend

echo "==> Restarting backend (migrations run automatically via entrypoint)..."
docker compose -f docker-compose.prod.yml up -d backend

echo "==> Cleaning up dangling images..."
docker image prune -f

echo "==> Done. Tail logs with: docker compose -f docker-compose.prod.yml logs -f backend"
```

Zapisz i ustaw uprawnienia:

```bash
chmod +x ~/apps/fitness-app/deploy.sh
```

### 6.2 Workflow

Od teraz cykl jest taki:

1. **Na laptopie** kodujesz, commitujesz, `git push origin main`.
2. **Na app-vm** odpalasz:

   ```bash
   ssh przemek@192.168.20.50
   ~/apps/fitness-app/deploy.sh
   ```

   Tyle. Skrypt ściągnie zmiany, przebuduje obraz, podniesie kontener, puści
   migracje z entrypoint.

### 6.3 Backupy bazy (zostawiamy na potem, ale)

Kiedy będziesz gotów, na db-vm dodasz cronowy `pg_dump`. Daj znać a dorzucę
sekcję.

---

## Sekcja 7 — Flutter APK podpięty do produkcji

Na laptopie, w katalogu repo:

```powershell
cd "C:\New folder\fitness-app\apps\mobile_web_flutter"
flutter pub get
dart run flutter_launcher_icons
```

### 7.1 Test debug — czy chodzi z prawdziwym backendem

Najpierw upewnij się, że telefon (albo emulator) dogada się z produkcyjnym
URL-em:

```powershell
flutter run --dart-define=API_BASE_URL=https://fitness.nodecrafts.org
```

Zaloguj się, dodaj wpis, sprawdź czy Today się odświeża. Jak działa — przechodzimy
do APK.

### 7.2 Stwórz keystore (jednorazowo)

Pełna instrukcja jest w
[apps/mobile_web_flutter/android/RELEASE.md](https://github.com/mailmen84/fitness-app/blob/main/apps/mobile_web_flutter/android/RELEASE.md).
Skrócona wersja:

```powershell
cd "C:\New folder\fitness-app\apps\mobile_web_flutter"
New-Item -ItemType Directory -Force android\keystore | Out-Null

keytool -genkeypair -v `
  -keystore android\keystore\upload-keystore.jks `
  -alias upload `
  -keyalg RSA -keysize 2048 -validity 10000
```

Zapamiętaj hasła. Skopiuj `android/key.properties.example` na
`android/key.properties` i wypełnij według instrukcji w RELEASE.md.

**WAŻNE:** `upload-keystore.jks` i `key.properties` są git-ignored. Backupuj
je w menedżerze haseł — bez nich nie wypuścisz update'u nikomu, kto już
zainstalował APK.

### 7.3 Zbuduj release APK

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://fitness.nodecrafts.org
```

Wynik: `build\app\outputs\flutter-apk\app-release.apk` (~40-60 MB).

### 7.4 Wgraj na telefon

1. Skopiuj APK na telefon (USB, AirDroid, Telegram do siebie — co wolisz).
2. Na telefonie tapnij plik APK.
3. Android zapyta o pozwolenie "Install unknown apps" dla menedżera plików
   albo przeglądarki, którą otworzyłeś APK. Zezwól.
4. Zainstaluj. Ikonka Fitness App pojawi się na home screenie.
5. Otwórz, zaloguj się tym samym kontem co w przeglądarce.

---

## Sekcja 8 — Troubleshooting + checklist

### Codzienny "is it alive" checklist

Na app-vm:

```bash
docker compose -f ~/apps/fitness-app/docker-compose.prod.yml ps
sudo systemctl status cloudflared --no-pager
curl -s -o /dev/null -w "%{http_code}\n" https://fitness.nodecrafts.org/api/v1/health
```

Trzy zielone (kontener Up, cloudflared active, HTTP 200) — wszystko gra.

### Typowe problemy

**APK nie loguje, "Connection refused" w aplikacji**
→ APK ma stary URL wbity w build. Zbuduj ponownie z poprawnym
`--dart-define=API_BASE_URL=https://fitness.nodecrafts.org`.

**Backend startuje, ale alembic crashuje na migracji**
→ Sprawdź `BACKEND_DATABASE_URL` w `.env`, czy app-vm dosięga 192.168.20.51:5432
(`PGPASSWORD=... psql -h 192.168.20.51 ...`).

**`https://fitness.nodecrafts.org` zwraca 502**
→ Backend padł albo nie startował. `docker compose -f docker-compose.prod.yml logs backend`.

**`https://fitness.nodecrafts.org` zwraca 530**
→ Cloudflared nie podpięty. `sudo systemctl restart cloudflared` + zerknij na
panel Cloudflare → Tunnels.

**Po restarcie app-vm nic nie wstaje**
→ Docker daemon wstał z autostartem, kontener `restart: unless-stopped` —
powinien sam wstać. Jeśli nie: `docker compose -f docker-compose.prod.yml up -d`.

### Pliki, których NIE wolno commitować

- `.env` (oba — na app-vm i lokalny dev)
- `apps/mobile_web_flutter/android/keystore/*`
- `apps/mobile_web_flutter/android/key.properties`

Te są już w `.gitignore`, ale lepiej raz na jakiś czas zerknąć w `git status`.

### Kontakt awaryjny z bazą

Z laptopa przez SSH tunel:

```powershell
ssh -L 5433:192.168.20.51:5432 przemek@192.168.20.50
```

W drugim oknie:

```powershell
psql -h 127.0.0.1 -p 5433 -U fitness_user -d fitness_app
```

(do tego trzeba mieć `psql` na laptopie albo użyć kontener Dockera
`postgres:16-alpine`).

---

## Podsumowanie — co ostatecznie chodzi

```
Telefon (APK)
   |
   v
https://fitness.nodecrafts.org   <-- Cloudflare Tunnel (TLS, brak portów)
   |
   v
app-vm  192.168.20.50            <-- cloudflared + Docker (FastAPI :8000)
   |
   v
db-vm   192.168.20.51            <-- PostgreSQL 16 (tylko z 20.50/32)
```

Update flow: `git push` na laptopie → `~/apps/fitness-app/deploy.sh` na app-vm.

Powodzenia. Jak coś nie wstaje, wracaj do mnie ze screenshotem komendy + jej
outputem — wskażę dokładne miejsce.
