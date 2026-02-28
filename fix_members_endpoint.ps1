# fix_members_endpoint.ps1
Write-Host "Fixing group members endpoint..." -ForegroundColor Cyan

# 1. Ensure RoomMembersView exists in views.py
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
    Write-Host "✅ Added RoomMembersView to views.py."
} else {
    Write-Host "RoomMembersView already exists." -ForegroundColor Green
}

# 2. Ensure the members URL is in urls.py
$urlsPath = "apps/chat/urls.py"
$urlsContent = Get-Content $urlsPath -Raw
if ($urlsContent -notmatch "room-members") {
    # Insert before the last closing bracket
    $newLine = "    path('rooms/<uuid:room_id>/members/', views.RoomMembersView.as_view(), name='room-members'),"
    $urlsContent = $urlsContent -replace '(\n\]$)', "`n$newLine`n]"
    Set-Content -Path $urlsPath -Value $urlsContent -Encoding UTF8
    Write-Host "✅ Added members endpoint to urls.py."
} else {
    Write-Host "Members endpoint already in urls.py." -ForegroundColor Green
}

# 3. Restart web container
Write-Host "Restarting web container..."
docker-compose restart web
Write-Host "✅ Done. Refresh the group info page."