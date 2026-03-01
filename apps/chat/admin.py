from django.contrib import admin
from .models import ChatRoom, Message, RoomMembership, MessageReadReceipt, MessageDeliveryReceipt

@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'room_type', 'created_by', 'created_at', 'last_message_at']
    list_filter = ['room_type', 'created_at']
    search_fields = ['name', 'id']
    filter_horizontal = ['participants']
    readonly_fields = ['id', 'created_at', 'updated_at']
    fieldsets = (
        (None, {
            'fields': ('name', 'room_type', 'created_by', 'participants')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'last_message_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'sender', 'room', 'content_truncated', 'message_type', 'created_at']
    list_filter = ['message_type', 'created_at', 'room']
    search_fields = ['content', 'sender__username', 'room__name']
    readonly_fields = ['id', 'created_at', 'updated_at']
    raw_id_fields = ['sender', 'room']
    
    def content_truncated(self, obj):
        return obj.content[:50] + ('...' if len(obj.content) > 50 else '')
    content_truncated.short_description = 'Content'

@admin.register(RoomMembership)
class RoomMembershipAdmin(admin.ModelAdmin):
    list_display = ['room', 'user', 'role', 'joined_at']
    list_filter = ['role']
    search_fields = ['room__name', 'user__username']
    raw_id_fields = ['room', 'user']

@admin.register(MessageReadReceipt)
class MessageReadReceiptAdmin(admin.ModelAdmin):
    list_display = ['message', 'user', 'read_at']
    list_filter = ['read_at']
    search_fields = ['message__content', 'user__username']

@admin.register(MessageDeliveryReceipt)
class MessageDeliveryReceiptAdmin(admin.ModelAdmin):
    list_display = ['message', 'user', 'delivered_at']
    list_filter = ['delivered_at']
    search_fields = ['message__content', 'user__username']
