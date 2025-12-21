param (
    [string]$ProjectName
)

if (-not $ProjectName) {
    $ProjectName = Read-Host "Projektname (z. B. finanzplaner)"
}

$ProjectName = $ProjectName.ToLower()

Write-Host "Initialisiere Projekt: $ProjectName" -ForegroundColor Cyan

# -------------------------
# Backend: Python venv
# -------------------------
if (Test-Path "backend/.venv") {
    Write-Host "Backend venv existiert bereits – überspringe"
} else {
    Write-Host "Erzeuge Python venv..."
    python -m venv backend/.venv
}

# -------------------------
# Frontend: env.local
# -------------------------
$frontendEnv = "frontend/.env.local"
if (-not (Test-Path $frontendEnv)) {
    Write-Host "Erzeuge frontend/.env.local"
    @"
BACKEND_URL=http://backend:8000
NEXT_PUBLIC_APP_NAME=$ProjectName
"@ | Out-File -Encoding utf8 $frontendEnv
}

# -------------------------
# docker-compose.yml anpassen
# -------------------------
$composeFile = "docker-compose.yml"
$content = Get-Content $composeFile -Raw

$content = $content `
    -replace "POSTGRES_USER:\s*.*", "POSTGRES_USER: $ProjectName" `
    -replace "POSTGRES_PASSWORD:\s*.*", "POSTGRES_PASSWORD: $ProjectName" `
    -replace "POSTGRES_DB:\s*.*", "POSTGRES_DB: $ProjectName" `
    -replace "postgresql\+psycopg://.*@postgres:5432/.*",
              "postgresql+psycopg://$ProjectName:$ProjectName@postgres:5432/$ProjectName"

Set-Content $composeFile $content

Write-Host "docker-compose.yml angepasst"

# -------------------------
# Hinweis
# -------------------------
Write-Host ""
Write-Host "Projekt '$ProjectName' initialisiert." -ForegroundColor Green
Write-Host "Nächste Schritte:"
Write-Host "  backend\.venv\Scripts\Activate.ps1"
Write-Host "  docker compose up -d --build"
