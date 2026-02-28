# fix_web_daphne.ps1
Write-Host "Adding Daphne to requirements.txt and rebuilding web..." -ForegroundColor Cyan

# Add daphne if not already present
$req = Get-Content "requirements.txt" -Raw
if ($req -notmatch "daphne") {
    Add-Content -Path "requirements.txt" -Value "`ndaphne==4.0.0" -Encoding UTF8
    Write-Host "✅ Added daphne to requirements.txt"
} else {
    Write-Host "✅ daphne already in requirements.txt"
}

# Rebuild and start the web container specifically
Write-Host "🔄 Rebuilding web container..."
docker-compose stop web
docker-compose rm -f web
docker-compose build web
docker-compose up -d web

Write-Host "⏳ Waiting 15 seconds for web to start..."
Start-Sleep -Seconds 15

# Check if web is running
$status = docker-compose ps web
if ($status -match "Up") {
    Write-Host "✅ Web container is running. Site should be accessible at http://localhost:8000" -ForegroundColor Green
} else {
    Write-Host "❌ Web container failed to start. Check logs: docker-compose logs web --tail=20" -ForegroundColor Red
}