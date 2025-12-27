# App Boilerplate – Next.js + FastAPI (KI-ready)

## Zweck dieses Repositories
Dieses Repository ist ein **wiederverwendbarer Rohbau (Boilerplate)** für moderne Web-Anwendungen.

Es dient als **stabile Grundlage** für verschiedene Projekte (z. B. Finanzplaner, Dashboards, interne Tools, MVPs)  
und ist so dokumentiert, dass **KI-Systeme sofort sinnvoll damit weiterarbeiten können**.

Der Fokus liegt auf:
- sauberer Architektur
- klarer Trennung von Frontend und Backend
- sicherer Authentifizierung
- einfacher Wiederverwendbarkeit

---

## Gesamtarchitektur (Überblick)

### Frontend
- **Next.js** (App Router)
- Zuständig für UI, Routing und API-Proxy
- Läuft auf Port `3000`

Frontend – Routing (Next.js App Router)

#### Frontend Details
Der Ordner frontend/finanzplaner/app/ ist der Router-Root von Next.js.

URL → Datei-Mapping
URL	Datei
/	app/page.tsx
/login	app/login/page.tsx
/register	app/register/page.tsx
/app	app/app/page.tsx
/api/*	app/api/[...path]/route.ts

Hinweis:
Der doppelte Ordner app/app/ ist korrekt:

erster app/ = Next.js Router-Root

zweiter app/ = URL-Segment /app

Geschützter Bereich (/app)

/app ist der geschützte Bereich

Zugriff nur für eingeloggte Nutzer

Login-Status wird serverseitig geprüft

Prüfung erfolgt über GET /api/me

Bei 401 erfolgt Redirect zu /login

Die Auth-Prüfung erfolgt bewusst nicht im Client.

#### API-Proxy (zentrales Konzept)

Alle API-Aufrufe des Frontends gehen immer über:

/api/...

Umsetzung

Datei: app/api/[...path]/route.ts

Fängt alle /api/* Requests ab

Leitet sie an das FastAPI-Backend weiter

Reicht Cookies automatisch durch

Beispiele

/api/health → backend:8000/api/health

/api/auth/login → backend:8000/api/auth/login

/api/me → backend:8000/api/me

Wichtige Regeln

Das Frontend ruft niemals direkt localhost:8000 oder backend:8000 auf

Auth funktioniert ausschließlich über Cookies

Kein CORS-Setup notwendig

### Backend
- **FastAPI** (Python)
- Zuständig für Business-Logik, Authentifizierung und Datenzugriff
- Läuft auf Port `8000`

#### Backend Details 
Backend – Datenbank & Migrationen

ORM: SQLAlchemy

Migrationen: Alembic

Migrationen liegen unter backend/alembic/versions/

Migrationen gehören immer ins Repository

Aktuelle Kern-Tabellen:

users

identities

### Datenbank
- **PostgreSQL**
- Zugriff über SQLAlchemy
- Migrationen mit Alembic

### Kommunikation
- Browser → Next.js (`localhost:3000`)
- Next.js → FastAPI (über internes Docker-Netzwerk)
- Frontend spricht **nie direkt** mit dem Backend

### Authentifizierung
- JWT
- Speicherung als **HttpOnly Cookie**
- Keine Token-Verarbeitung im Frontend

### Authentifizierung Details
Authentifizierung (stabiler Kern)
Backend

JWT (HS256)

Secret über JWT_SECRET (Dev-Default vorhanden)

JWT wird als HttpOnly Cookie gesetzt

Frontend

JWT wird niemals gelesen

Login/Register über /api/auth/*

Logout löscht Cookie serverseitig

Stabile Endpunkte

POST /api/auth/register

POST /api/auth/login

POST /api/auth/logout

GET /api/me

GET /api/health

Diese Endpunkte gelten als Kernfunktionalität.

### Containerisierung
- Docker Compose
- Services: `frontend`, `backend`, `postgres`

#### Containerisierung Details
Lokaler Start (Docker)
docker compose up -d --build

Dienste

Frontend: http://localhost:3000

Backend: http://localhost:8000

Health (über Proxy): http://localhost:3000/api/health

---

## Projektstruktur (Root)

```text
.
├── docker-compose.yml
├── scripts/
│   └── init-project.ps1
├── backend/
│   ├── main.py
│   ├── db.py
│   ├── models.py
│   ├── auth_jwt.py
│   ├── auth_password.py
│   ├── requirements.txt
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/
│   └── Dockerfile
└── frontend/
    ├── app/
    │   ├── layout.tsx
    │   ├── page.tsx          # /app (geschützter Bereich)
    │   ├── login/
    │   ├── register/
    │   └── api/[...path]/    # Proxy zum Backend
    ├── package.json
    ├── Dockerfile
