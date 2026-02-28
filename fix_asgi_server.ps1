# fix_asgi_server.ps1
$composePath = "docker-compose.yml"
$content = Get-Content $composePath -Raw

# Replace the runserver command with daphne
$newContent = $content -replace 'python manage\.py runserver 0\.0\.0\.0:8000', 'daphne -b 0.0.0.0 -p 8000 chat_project.asgi:application'

Set-Content -Path $composePath -Value $newContent -Encoding UTF8
Write-Host "Updated docker-compose.yml to use daphne."

Write-Host "Rebuilding containers..."
docker-compose down
docker-compose up -d --build

Write-Host "Waiting 30 seconds for services to start..."
Start-Sleep -Seconds 30

Write-Host "Done. Now test your chat - WebSockets should work."