# fix_back_button_only.ps1
$roomHtmlPath = "templates/chat/room.html"
$content = Get-Content $roomHtmlPath -Raw

# Replace the arrow button with a plain "Back" button
$pattern = '<button onclick="window\.location\.href=''\/''" style="margin-right: 10px; background: none; border: none; font-size: 24px; cursor: pointer;">←</button>'
$replacement = '<button onclick="window.location.href=''\/''" style="margin-right: 10px; background: none; border: none; font-size: 16px; cursor: pointer; padding: 5px 10px;">Back</button>'
$content = $content -replace $pattern, $replacement

Set-Content -Path $roomHtmlPath -Value $content -Encoding UTF8
Write-Host "✅ Back button updated. Refresh your browser."