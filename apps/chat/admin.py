from django.contrib import admin
from .models import ChatRoom, Message

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
