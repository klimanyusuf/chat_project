import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import ChatRoom, Message
from apps.ai_assistant.tasks import generate_smart_replies
from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)
User = get_user_model()

@database_sync_to_async
def get_user_from_token(token):
    try:
        access_token = AccessToken(token)
        user = User.objects.get(id=access_token['user_id'])
        return user
    except Exception as e:
        logger.error(f"Token error: {e}")
        return None

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'chat_{self.room_id}'

        # Extract token from query string
        query_string = self.scope['query_string'].decode()
        token = None
        if 'token=' in query_string:
            token = query_string.split('token=')[-1].split('&')[0]

        if token:
            self.user = await get_user_from_token(token)
        else:
            self.user = None

        if not self.user or self.user.is_anonymous:
            logger.warning(f"WebSocket connection rejected: invalid token for room {self.room_id}")
            await self.close(code=4001)
            return

        if not await self.has_room_access():
            logger.warning(f"User {self.user.id} denied access to room {self.room_id}")
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()
        await self.set_user_online(True)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_online',
                'user_id': self.user.id,
                'username': self.user.username
            }
        )

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        await self.set_user_online(False)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_offline',
                'user_id': self.user.id,
                'username': self.user.username
            }
        )

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'message')

            if message_type == 'message':
                await self.handle_message(data)
            elif message_type == 'typing':
                await self.handle_typing(data)
            elif message_type == 'read_receipt':
                await self.handle_read_receipt(data)

        except Exception as e:
            logger.error(f"Error in receive: {e}")

    async def handle_message(self, data):
        content = data.get('content')
        if not content:
            return

        message = await self.save_message(content)
        await self.update_room_last_message()

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message_id': str(message.id),
                'user_id': self.user.id,
                'username': self.user.username,
                'content': content,
                'timestamp': message.created_at.isoformat()
            }
        )

        await self.trigger_smart_replies()

    async def handle_typing(self, data):
        is_typing = data.get('is_typing', False)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator',
                'user_id': self.user.id,
                'username': self.user.username,
                'is_typing': is_typing
            }
        )

    async def handle_read_receipt(self, data):
        message_ids = data.get('message_ids', [])
        if message_ids:
            await self.mark_messages_read(message_ids)
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'messages_read',
                    'user_id': self.user.id,
                    'username': self.user.username,
                    'message_ids': message_ids,
                    'timestamp': timezone.now().isoformat()
                }
            )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'type': 'new_message',
            'message_id': event['message_id'],
            'user_id': event['user_id'],
            'username': event['username'],
            'content': event['content'],
            'timestamp': event['timestamp']
        }))

    async def typing_indicator(self, event):
        await self.send(text_data=json.dumps({
            'type': 'typing',
            'user_id': event['user_id'],
            'username': event['username'],
            'is_typing': event['is_typing']
        }))

    async def user_online(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_online',
            'user_id': event['user_id'],
            'username': event['username']
        }))

    async def user_offline(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_offline',
            'user_id': event['user_id'],
            'username': event['username']
        }))

    async def messages_read(self, event):
        await self.send(text_data=json.dumps({
            'type': 'messages_read',
            'user_id': event['user_id'],
            'username': event['username'],
            'message_ids': event['message_ids'],
            'timestamp': event['timestamp']
        }))

    @database_sync_to_async
    def has_room_access(self):
        try:
            room = ChatRoom.objects.get(id=self.room_id)
            return room.participants.filter(id=self.user.id).exists()
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content):
        return Message.objects.create(
            room_id=self.room_id,
            sender=self.user,
            content=content
        )

    @database_sync_to_async
    def update_room_last_message(self):
        ChatRoom.objects.filter(id=self.room_id).update(
            last_message_at=timezone.now()
        )

    @database_sync_to_async
    def set_user_online(self, is_online):
        self.user.is_online = is_online
        self.user.last_seen = timezone.now()
        self.user.save(update_fields=['is_online', 'last_seen'])

    @database_sync_to_async
    def trigger_smart_replies(self):
        room = ChatRoom.objects.get(id=self.room_id)
        other_users = room.participants.exclude(id=self.user.id)
        for user in other_users:
            generate_smart_replies.delay(str(self.room_id), user.id)

    @database_sync_to_async
    def mark_messages_read(self, message_ids):
        from .models import MessageReadReceipt
        messages = Message.objects.filter(id__in=message_ids, room_id=self.room_id).exclude(
            read_receipts__user=self.user
        )
        for message in messages:
            MessageReadReceipt.objects.get_or_create(
                message=message,
                user=self.user,
                defaults={'read_at': timezone.now()}
            )
