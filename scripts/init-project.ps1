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
Write-Host ""
Write-Host "Next steps:"
Write-Host "  docker compose up -d --build"
Write-Host "  http://localhost:3000/api/health"


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