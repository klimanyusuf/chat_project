# fix_admin_and_group.ps1
Write-Host "Fixing admin panel and group info page..." -ForegroundColor Cyan

# 1. Register all models in admin.py
$accountsAdminPath = "apps/accounts/admin.py"
$accountsAdminContent = @'
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ['email', 'username', 'is_online', 'last_seen', 'is_active']
    list_filter = ['is_online', 'is_active', 'date_joined']
    search_fields = ['email', 'username']
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('is_online', 'last_seen', 'avatar', 'bio')}),
    )
'@
Set-Content -Path $accountsAdminPath -Value $accountsAdminContent -Encoding UTF8
Write-Host "✅ apps/accounts/admin.py updated."

$chatAdminPath = "apps/chat/admin.py"
$chatAdminContent = @'
from django.contrib import admin
from .models import ChatRoom, Message, RoomMembership, MessageReadReceipt, MessageDeliveryReceipt

@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'room_type', 'created_by', 'created_at']
    list_filter = ['room_type', 'created_at']
    search_fields = ['name']
    filter_horizontal = ['participants']

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'sender', 'room', 'message_type', 'created_at']
    list_filter = ['message_type', 'created_at']
    search_fields = ['content']
    date_hierarchy = 'created_at'

@admin.register(RoomMembership)
class RoomMembershipAdmin(admin.ModelAdmin):
    list_display = ['room', 'user', 'role', 'joined_at']
    list_filter = ['role']

@admin.register(MessageReadReceipt)
class MessageReadReceiptAdmin(admin.ModelAdmin):
    list_display = ['message', 'user', 'read_at']

@admin.register(MessageDeliveryReceipt)
class MessageDeliveryReceiptAdmin(admin.ModelAdmin):
    list_display = ['message', 'user', 'delivered_at']
'@
Set-Content -Path $chatAdminPath -Value $chatAdminContent -Encoding UTF8
Write-Host "✅ apps/chat/admin.py updated."

# 2. Replace group_info.html with a working version
$groupInfoPath = "templates/group_info.html"
$groupInfoContent = @'
<!DOCTYPE html>
<html>
<head>
    <title>Group Info</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { display: flex; align-items: center; gap: 10px; border-bottom: 1px solid #ccc; padding-bottom: 10px; margin-bottom: 20px; }
        .back-btn { text-decoration: none; font-size: 16px; color: #000; }
        .member-list { list-style: none; padding: 0; }
        .member-item { display: flex; justify-content: space-between; align-items: center; padding: 10px; border-bottom: 1px solid #eee; }
        .member-name { font-weight: bold; }
        .admin-badge { background: #ff9800; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; }
        .loading { text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <a href="javascript:history.back()" class="back-btn">Back</a>
        <h2 id="room-name">Group Info</h2>
    </div>
    <div id="loading" class="loading">Loading members...</div>
    <ul id="member-list" class="member-list" style="display: none;"></ul>

    <script>
        const roomId = window.location.pathname.split('/')[2];
        const token = localStorage.getItem('token');

        if (!token) {
            alert('Not logged in');
            window.location.href = '/';
        }

        async function loadMembers() {
            try {
                const res = await fetch(`/api/chat/rooms/${roomId}/members/`, {
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                if (res.ok) {
                    const members = await res.json();
                    document.getElementById('loading').style.display = 'none';
                    const list = document.getElementById('member-list');
                    list.style.display = 'block';
                    list.innerHTML = '';
                    members.forEach(m => {
                        const li = document.createElement('li');
                        li.className = 'member-item';
                        li.innerHTML = `<span class="member-name">${m.username}</span>`;
                        if (m.role === 'admin') {
                            li.innerHTML += '<span class="admin-badge">Admin</span>';
                        }
                        list.appendChild(li);
                    });
                } else {
                    document.getElementById('loading').innerText = 'Failed to load members';
                }
            } catch (e) {
                console.error(e);
                document.getElementById('loading').innerText = 'Error loading members';
            }
        }

        loadMembers();
    </script>
</body>
</html>
'@
Set-Content -Path $groupInfoPath -Value $groupInfoContent -Encoding UTF8
Write-Host "✅ templates/group_info.html updated."

# 3. Restart web container to apply changes
Write-Host "Restarting web container..."
docker-compose restart web
Write-Host "✅ Done. Check admin panel and group info page."