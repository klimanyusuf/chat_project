# final_websocket_fix.ps1 – Clean version
Write-Host "🔧 PERMANENT WEBSOCKET FIX" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# 1. Ensure all routing files are correct
$chatRouting = @'
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<room_id>[0-9a-f-]+)/$', consumers.ChatConsumer.as_asgi()),
]
'@
Set-Content -Path "apps/chat/routing.py" -Value $chatRouting -Encoding UTF8
Write-Host "✅ apps/chat/routing.py – verified"

$aiRouting = @'
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/smart-reply/(?P<room_id>[0-9a-f-]+)/$', consumers.SmartReplyConsumer.as_asgi()),
]
'@
Set-Content -Path "apps/ai_assistant/routing.py" -Value $aiRouting -Encoding UTF8
Write-Host "✅ apps/ai_assistant/routing.py – verified"

# 2. Correct ASGI configuration
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
Write-Host "✅ chat_project/asgi.py – verified"

# 3. Ensure ASGI_APPLICATION is set in settings.py
$settingsPath = "chat_project/settings.py"
$settings = Get-Content $settingsPath -Raw
if ($settings -notmatch "ASGI_APPLICATION\s*=\s*'chat_project\.asgi\.application'") {
    $settings = $settings -replace "(?<=WSGI_APPLICATION.*?\n)", "ASGI_APPLICATION = 'chat_project.asgi.application'`n"
    Set-Content -Path $settingsPath -Value $settings -Encoding UTF8
    Write-Host "✅ Added ASGI_APPLICATION to settings.py"
} else {
    Write-Host "✅ ASGI_APPLICATION already set"
}

# 4. Completely reset Docker environment
Write-Host "🔄 Stopping and removing all containers (including volumes)..." -ForegroundColor Yellow
docker-compose down -v
Write-Host "🔄 Rebuilding and starting containers..." -ForegroundColor Yellow
docker-compose up -d --build

Write-Host "⏳ Waiting 40 seconds for services to fully initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 40

# 5. Verify WebSocket routes are registered (using docker-compose exec)
Write-Host "🔍 Checking registered WebSocket routes..." -ForegroundColor Cyan
docker-compose exec web python -c "
import django
django.setup()
try:
    from apps.chat.routing import websocket_urlpatterns as chat_routes
    print('Chat routes:')
    for p in chat_routes:
        print(f'  {p.pattern}')
except ImportError as e:
    print(f'Could not import chat routes: {e}')
try:
    from apps.ai_assistant.routing import websocket_urlpatterns as ai_routes
    print('AI routes:')
    for p in ai_routes:
        print(f'  {p.pattern}')
except ImportError as e:
    print(f'Could not import AI routes: {e}')
"

Write-Host "`n✅ FIX COMPLETE" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Now test the application:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8000 in TWO different browsers." -ForegroundColor White
Write-Host "2. Log in as Alice and Bob (alice@example.com / bob@example.com, password: password123)." -ForegroundColor White
Write-Host "3. From Alice's dashboard, click on Bob to start a private chat." -ForegroundColor White
Write-Host "4. In the new room, open the browser console (F12) and watch for 'Connected to chat room' messages (no red errors)." -ForegroundColor White
Write-Host "5. Send a message – it should appear instantly on the other side." -ForegroundColor White
Write-Host "6. Pause typing – fallback smart replies should appear." -ForegroundColor White
Write-Host "`nIf you still see WebSocket errors, please share the output of:" -ForegroundColor Cyan
Write-Host "   docker-compose logs web --tail=50" -ForegroundColor White
Write-Host "   docker-compose logs celery --tail=20" -ForegroundColor White
Write-Host "and the browser console errors." -ForegroundColor White