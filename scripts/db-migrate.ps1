param (
    [string]$Message = ""
)

Write-Host "🔄 Rebuilding backend container..."
docker compose up -d --build backend

Write-Host "⏳ Waiting for backend to be ready..."
Start-Sleep -Seconds 3

if ($Message -ne "") {
    Write-Host "📝 Creating new migration: $Message"
    docker compose exec backend python -m alembic revision --autogenerate -m "$Message"
}

Write-Host "⬆ Applying migrations..."
docker compose exec backend python -m alembic upgrade head

Write-Host "✅ Migration process finished."
