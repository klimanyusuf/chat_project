# fix_websocket_simple.ps1
Write-Host "FIXING WEBSOCKET ROUTING" -ForegroundColor Cyan

# 1. Write chat/routing.py
$chatRouting = @'
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<room_id>[0-9a-f-]+)/$', consumers.ChatConsumer.as_asgi()),
]
'@
Set-Content -Path "apps/chat/routing.py" -Value $chatRouting -Encoding UTF8
Write-Host "Updated apps/chat/routing.py"

# 2. Write ai_assistant/routing.py
$aiRouting = @'
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/smart-reply/(?P<room_id>[0-9a-f-]+)/$', consumers.SmartReplyConsumer.as_asgi()),
]
'@
Set-Content -Path "apps/ai_assistant/routing.py" -Value $aiRouting -Encoding UTF8
Write-Host "Updated apps/ai_assistant/routing.py"

# 3. Write asgi.py
$asgi = @'
import os
import django
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_project.settings')
django.setup()

from apps.chat.routing import websocket_urlpatterns as chat_websocket
from apps.ai_assistant.routing import websocket_urlpatterns as ai_websocket

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(
            chat_websocket + ai_websocket
        )
    ),
})
'@
Set-Content -Path "chat_project/asgi.py" -Value $asgi -Encoding UTF8
Write-Host "Updated chat_project/asgi.py"

# 4. Ensure ASGI_APPLICATION in settings.py
$settingsPath = "chat_project/settings.py"
$settings = Get-Content $settingsPath -Raw
if ($settings -notmatch "ASGI_APPLICATION\s*=\s*'chat_project\.asgi\.application'") {
    $settings = $settings -replace "(?<=WSGI_APPLICATION.*?\n)", "ASGI_APPLICATION = 'chat_project.asgi.application'`n"
    Set-Content -Path $settingsPath -Value $settings -Encoding UTF8
    Write-Host "Added ASGI_APPLICATION to settings.py"
} else {
    Write-Host "ASGI_APPLICATION already set"
}

# 5. Rebuild Docker
Write-Host "Rebuilding Docker containers..." -ForegroundColor Yellow
docker-compose down -v
docker-compose up -d --build

Write-Host "Waiting 30 seconds for services to start..."
Start-Sleep -Seconds 30

Write-Host "FIX COMPLETE" -ForegroundColor Green
Write-Host "Now open your browser and test the chat."