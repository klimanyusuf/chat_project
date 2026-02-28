# fix_roomId_and_websocket.ps1
$roomHtmlPath = "templates/chat/room.html"
$content = Get-Content $roomHtmlPath -Raw

# Replace the roomId extraction with a robust regex
$newExtraction = @'
    const path = window.location.pathname;
    const matches = path.match(/\/room\/([0-9a-f-]+)/);
    const roomId = matches ? matches[1] : null;
    if (!roomId) {
        alert('Invalid room URL. Redirecting to dashboard.');
        window.location.href = '/';
    }
'@
$content = $content -replace '(?s)const roomId = window\.location\.pathname\.split.*?;.*?(?=const token)', $newExtraction

# Also ensure the smart reply WebSocket uses the same roomId variable (already does)
Set-Content -Path $roomHtmlPath -Value $content -Encoding UTF8
Write-Host "✅ Fixed roomId extraction and added validation."

docker-compose restart web
Write-Host "✅ Web container restarted. Refresh your browser."