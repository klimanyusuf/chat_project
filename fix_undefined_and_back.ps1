# fix_undefined_and_back.ps1
$roomHtmlPath = "templates/chat/room.html"
$content = Get-Content $roomHtmlPath -Raw

# Replace the back link with a button
$newBackButton = @'
    <div style="display: flex; align-items: center; padding: 10px; border-bottom: 1px solid #ccc; background: white;">
        <button onclick="window.location.href='/'" style="margin-right: 10px; background: none; border: none; font-size: 24px; cursor: pointer;">←</button>
'@
$content = $content -replace '<div style="display: flex; align-items: center; padding: 10px; border-bottom: 1px solid #ccc; background: white;">\s*<a href="/".*?←.*?</a>', $newBackButton

# Fix loadMessages to map REST API format to displayMessage format
$loadMessagesFix = @'
    async function loadMessages() {
        try {
            const res = await fetch(`/api/chat/rooms/${roomId}/messages/`, { headers: { 'Authorization': `Bearer ${token}` } });
            if (res.ok) {
                const messages = await res.json();
                messages.forEach(msg => {
                    displayMessage({
                        username: msg.sender ? msg.sender.username : 'Unknown',
                        content: msg.content,
                        timestamp: msg.created_at
                    });
                });
            }
        } catch (e) { console.error(e); }
    }
'@
$content = $content -replace '(?s)async function loadMessages\(\).*?}', $loadMessagesFix

Set-Content -Path $roomHtmlPath -Value $content -Encoding UTF8
Write-Host "✅ Fixed undefined username and back button."
docker-compose restart web
Write-Host "✅ Web container restarted. Refresh your browser."