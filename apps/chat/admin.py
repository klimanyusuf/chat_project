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
