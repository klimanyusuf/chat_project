# fix_undefined_username_and_back_button.ps1
$roomHtmlPath = "templates/chat/room.html"
$content = Get-Content $roomHtmlPath -Raw

# Fix 1: Replace the back link with a button
$newBackButton = @'
    <div style="display: flex; align-items: center; padding: 10px; border-bottom: 1px solid #ccc; background: white;">
        <button onclick="window.location.href='/'" style="margin-right: 10px; background: none; border: none; font-size: 24px; cursor: pointer;">←</button>
'@
$content = $content -replace '<div style="display: flex; align-items: center; padding: 10px; border-bottom: 1px solid #ccc; background: white;">\s*<a href="/".*?←.*?</a>', $newBackButton

# Fix 2: Modify loadMessages to map REST response to expected format
$loadMessagesFix = @'
    async function loadMessages() {
        try {
            const res = await fetch(`/api/chat/rooms/${roomId}/messages/`, { headers: { 'Authorization': `Bearer ${token}` } });
            if (res.ok) {
                const messages = await res.json();
                messages.forEach(msg => {
                    // Convert REST API format to the format expected by displayMessage
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

# Replace the existing loadMessages function
$content = $content -replace '(?s)async function loadMessages\(\).*?}', $loadMessagesFix

# Fix 3: Enhance displayMessage to handle both formats (already uses data.username, but ensure it's there)
# Optionally add a fallback
$displayMessageFix = @'
    function displayMessage(data) {
        const messagesDiv = document.getElementById('messages');
        const msgDiv = document.createElement('div');
        msgDiv.style.margin = '10px 0';
        msgDiv.style.display = 'flex';
        msgDiv.style.flexDirection = 'column';
        msgDiv.style.alignItems = data.username === currentUsername ? 'flex-end' : 'flex-start';

        const bubbleWrapper = document.createElement('div');
        bubbleWrapper.style.maxWidth = '70%';

        // For group chats, show sender name if not current user
        if (roomDetails && roomDetails.room_type === 'group' && data.username !== currentUsername) {
            const nameSpan = document.createElement('div');
            nameSpan.style.fontSize = '12px';
            nameSpan.style.fontWeight = 'bold';
            nameSpan.style.marginBottom = '2px';
            nameSpan.style.color = '#666';
            nameSpan.innerText = data.username;
            bubbleWrapper.appendChild(nameSpan);
        }

        const bubble = document.createElement('div');
        bubble.style.padding = '8px 12px';
        bubble.style.borderRadius = '12px';
        bubble.style.wordWrap = 'break-word';

        if (data.username === currentUsername) {
            bubble.style.background = '#dcf8c6';
            bubble.style.marginLeft = 'auto';
        } else {
            bubble.style.background = 'white';
            bubble.style.marginRight = 'auto';
        }

        bubble.innerHTML = data.content;
        bubbleWrapper.appendChild(bubble);

        const timeSpan = document.createElement('div');
        timeSpan.style.fontSize = '10px';
        timeSpan.style.color = '#999';
        timeSpan.style.marginTop = '2px';
        timeSpan.style.textAlign = 'right';
        timeSpan.innerText = new Date(data.timestamp).toLocaleTimeString();
        bubbleWrapper.appendChild(timeSpan);

        msgDiv.appendChild(bubbleWrapper);
        messagesDiv.appendChild(msgDiv);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }
'@

# Replace displayMessage (but careful not to replace other occurrences)
# Use a more specific pattern to match the entire function
$content = $content -replace '(?s)function displayMessage\(data\).*?}', $displayMessageFix

# Write back
Set-Content -Path $roomHtmlPath -Value $content -Encoding UTF8
Write-Host "✅ Fixed undefined username and back button."

# Optionally restart web to apply template changes (not strictly needed as volume is mounted)
Write-Host "Restarting web container to ensure changes are picked up..."
docker-compose restart web
Write-Host "Done. Refresh your browser."