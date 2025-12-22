param(
  [Parameter(Mandatory=$false, Position=0)]
  [string]$ProjectName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = Read-Host "Project name (e.g. finanzplaner)"
}

$ProjectName = $ProjectName.Trim().ToLower()

Write-Host "Initializing project: $ProjectName" -ForegroundColor Cyan

# -------------------------
# Backend: Python venv
# -------------------------
$venvPath = "backend/.venv"
if (Test-Path $venvPath) {
  Write-Host "Backend venv already exists - skipping" -ForegroundColor Yellow
} else {
  Write-Host "Creating Python venv at $venvPath"
  python -m venv $venvPath
}

# -------------------------
# Backend: pip install -r requirements.txt (optional but recommended)
# -------------------------
$pythonExe = Join-Path $venvPath "Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
  throw "Could not find venv python at $pythonExe"
}

if (Test-Path "backend/requirements.txt") {
  Write-Host "Installing backend dependencies (pip install -r requirements.txt)..." -ForegroundColor Green
  & $pythonExe -m pip install --upgrade pip
  & $pythonExe -m pip install -r "backend/requirements.txt"
  Write-Host "Backend dependencies installed." -ForegroundColor Green
} else {
  Write-Host "backend/requirements.txt not found - skipping pip install" -ForegroundColor Yellow
}

# -------------------------
# Frontend: .env.local
# -------------------------
$frontendEnv = "frontend/.env.local"
if (Test-Path $frontendEnv) {
  Write-Host ".env.local already exists - skipping" -ForegroundColor Yellow
} else {
@"
BACKEND_URL=http://backend:8000
NEXT_PUBLIC_APP_NAME=$ProjectName
"@ | Out-File -Encoding utf8 $frontendEnv
  Write-Host "Created frontend/.env.local"
}

# -------------------------
# docker-compose.yml update
# -------------------------
$composeFile = "docker-compose.yml"
if (-not (Test-Path $composeFile)) {
  throw "docker-compose.yml not found. Run this script from repo root."
}

$content = Get-Content $composeFile -Raw

$content = [regex]::Replace($content, '(?m)^\s*POSTGRES_USER:\s*.*$', "      POSTGRES_USER: $ProjectName")
$content = [regex]::Replace($content, '(?m)^\s*POSTGRES_PASSWORD:\s*.*$', "      POSTGRES_PASSWORD: $ProjectName")
$content = [regex]::Replace($content, '(?m)^\s*POSTGRES_DB:\s*.*$', "      POSTGRES_DB: $ProjectName")

$dsn = "postgresql+psycopg://${ProjectName}:${ProjectName}@postgres:5432/${ProjectName}"
$content = [regex]::Replace($content, '(?m)^\s*DATABASE_URL:\s*.*$', "      DATABASE_URL: $dsn")

Set-Content -Path $composeFile -Value $content -Encoding utf8
Write-Host "docker-compose.yml updated successfully" -ForegroundColor Green

# -------------------------
# Frontend: npm install (optional)
# -------------------------
Write-Host ""
Write-Host "Checking for npm..." -ForegroundColor Cyan

$npmExists = Get-Command npm -ErrorAction SilentlyContinue

if ($npmExists) {
  Write-Host "npm found. Installing frontend dependencies..." -ForegroundColor Green
  Push-Location "frontend"
  npm install
  Pop-Location
  Write-Host "npm install completed." -ForegroundColor Green
} else {
  Write-Host "npm not found. Skipping frontend dependency install." -ForegroundColor Yellow
  Write-Host "You can install dependencies later with:" -ForegroundColor Yellow
  Write-Host "  cd frontend && npm install" -ForegroundColor Yellow
}


# -------------------------
# Optional: reset database volume (project-local only)
# -------------------------
Write-Host ""
Write-Host "Database setup:" -ForegroundColor Cyan
Write-Host "If this is a NEW project, the database volume should be reset." -ForegroundColor Cyan
Write-Host "This will REMOVE ONLY the database volume of THIS project." -ForegroundColor Yellow
Write-Host "Other projects are NOT affected." -ForegroundColor Yellow

$resetDb = Read-Host "Reset database volume now? (y/N)"

if ($resetDb -match '^(y|yes)$') {
  Write-Host "Stopping containers and removing project-local volumes..." -ForegroundColor Red
  docker compose down -v
  Write-Host "Database volume removed for this project." -ForegroundColor Green
} else {
  Write-Host "Keeping existing database volume." -ForegroundColor Yellow
}
# -------------------------
# Docker: start stack (optional) + run migrations in container
# -------------------------
Write-Host ""
Write-Host "Starting docker compose stack (frontend/backend/postgres)..." -ForegroundColor Cyan
docker compose up -d --build | Out-Null
Write-Host "Docker stack started." -ForegroundColor Green

Write-Host "Running migrations inside backend container..." -ForegroundColor Cyan
try {
  docker compose exec backend python -m alembic upgrade head
  Write-Host "Migrations applied (alembic upgrade head)." -ForegroundColor Green
} catch {
  Write-Host "Could not run alembic in container. If backend container is still starting, wait a moment and run:" -ForegroundColor Yellow
  Write-Host "  docker compose exec backend python -m alembic upgrade head" -ForegroundColor Yellow
  throw
}

Write-Host ""
Write-Host "Next steps / checks:" -ForegroundColor Cyan
Write-Host "  http://localhost:3000/api/health"
Write-Host "  Register/Login via http://localhost:3000/register"

# -------------------------
# Run migrations in backend container (alembic)
# -------------------------
Write-Host ""
Write-Host "Running database migrations (alembic upgrade head)..." -ForegroundColor Cyan

$maxAttempts = 10
for ($i = 1; $i -le $maxAttempts; $i++) {
  try {
    docker compose exec backend python -m alembic upgrade head
    Write-Host "Migrations applied successfully." -ForegroundColor Green
    break
  } catch {
    if ($i -eq $maxAttempts) {
      Write-Host "Failed to run migrations after $maxAttempts attempts." -ForegroundColor Red
      Write-Host "Try manually:" -ForegroundColor Yellow
      Write-Host "  docker compose exec backend python -m alembic upgrade head" -ForegroundColor Yellow
      throw
    }
    Write-Host "Backend not ready yet (attempt $i/$maxAttempts). Waiting 2s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
  }
}
