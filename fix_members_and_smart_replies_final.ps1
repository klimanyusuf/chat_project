# fix_members_and_smart_replies_final.ps1
Write-Host "Fixing members endpoint and improving smart replies..." -ForegroundColor Cyan

# Backup
$backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item "apps/chat/views.py" "$backupDir/views.py.bak"
Copy-Item "apps/chat/urls.py" "$backupDir/urls.py.bak"
Copy-Item "apps/ai_assistant/tasks.py" "$backupDir/tasks.py.bak" -ErrorAction SilentlyContinue
Copy-Item "apps/ai_assistant/services.py" "$backupDir/services.py.bak" -ErrorAction SilentlyContinue
Write-Host "Backups saved to $backupDir"

# 1. Add RoomMembersView to views.py if missing
$viewsPath = "apps/chat/views.py"
$viewsContent = Get-Content $viewsPath -Raw
if ($viewsContent -notmatch "class RoomMembersView") {
    $viewsContent += @'
class RoomMembersView(generics.ListAPIView):
    """List members of a room with their roles"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, room_id):
        from .models import RoomMembership
        memberships = RoomMembership.objects.filter(room_id=room_id).select_related('user')
        data = [{
            'id': m.user.id,
            'username': m.user.username,
            'role': m.role,
            'joined_at': m.joined_at.isoformat()
        } for m in memberships]
        return Response(data)
'@
    Set-Content -Path $viewsPath -Value $viewsContent -Encoding UTF8
    Write-Host "Added RoomMembersView to views.py."
} else {
    Write-Host "RoomMembersView already exists."
}

# 2. Ensure the members URL is in urls.py (using single-quoted here-string for the new line)
$urlsPath = "apps/chat/urls.py"
$urlsContent = Get-Content $urlsPath -Raw
if ($urlsContent -notmatch "room-members") {
    $newLine = @'
    path('rooms/<uuid:room_id>/members/', views.RoomMembersView.as_view(), name='room-members'),
'@
    $urlsContent = $urlsContent -replace '(\n\]$)', "`n$newLine`n]"
    Set-Content -Path $urlsPath -Value $urlsContent -Encoding UTF8
    Write-Host "Added members endpoint to urls.py."
} else {
    Write-Host "Members endpoint already in urls.py."
}

# 3. Improve smart reply task
$tasksPath = "apps/ai_assistant/tasks.py"
$tasksContent = @'
from celery import shared_task
import asyncio
import logging
from channels.layers import get_channel_layer
from .services import SmartReplyService
from apps.chat.models import Message

logger = logging.getLogger(__name__)

@shared_task
def generate_smart_replies(room_id, user_id):
    """Generate smart reply suggestions asynchronously"""
    try:
        messages = Message.objects.filter(
            room_id=room_id
        ).select_related('sender').order_by('-created_at')[:10]
        
        if len(messages) < 2:
            logger.info(f"Not enough messages for room {room_id}")
            return
        
        history = []
        for msg in reversed(messages):
            if msg.sender:
                history.append(f"{msg.sender.username}: {msg.content}")
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        service = SmartReplyService()
        suggestions = loop.run_until_complete(
            service.get_suggestions(room_id, user_id, history)
        )
        
        if suggestions:
            channel_layer = get_channel_layer()
            loop.run_until_complete(
                channel_layer.group_send(
                    f'smart_reply_{room_id}',
                    {
                        'type': 'smart_replies',
                        'suggestions': suggestions,
                        'target_user_id': user_id
                    }
                )
            )
            logger.info(f"Sent {len(suggestions)} suggestions to user {user_id}")
        else:
            logger.info("No suggestions generated")
        
        loop.close()
        
    except Exception as e:
        logger.error(f"Smart reply generation failed: {e}", exc_info=True)
'@
Set-Content -Path $tasksPath -Value $tasksContent -Encoding UTF8
Write-Host "Updated smart reply task."

# 4. Ensure services.py uses Gemini
$servicesPath = "apps/ai_assistant/services.py"
$servicesContent = Get-Content $servicesPath -Raw
$servicesContent = $servicesContent -replace 'self\.adapter = .*', 'self.adapter = GeminiSmartReplyAdapter()'
Set-Content -Path $servicesPath -Value $servicesContent -Encoding UTF8
Write-Host "Ensured services.py uses Gemini."

# 5. Restart containers
Write-Host "Restarting web and celery containers..."
docker-compose restart web celery
Write-Host "Done. Test the group info page and smart replies."