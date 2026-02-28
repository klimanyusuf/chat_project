import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .services import SmartReplyService
from apps.chat.models import Message
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
        logger.error(f"SmartReply token error: {e}")
        return None

class SmartReplyConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']

        query_string = self.scope['query_string'].decode()
        token = None
        if 'token=' in query_string:
            token = query_string.split('token=')[-1].split('&')[0]

        if token:
            self.user = await get_user_from_token(token)
        else:
            self.user = None

        if not self.user or self.user.is_anonymous:
            await self.close()
            return

        if not await self.has_room_access():
            await self.close()
            return

        self.room_group_name = f'smart_reply_{self.room_id}'
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            if data.get('type') == 'request_suggestions':
                await self.generate_suggestions()
        except Exception as e:
            logger.error(f"Error in smart reply consumer: {e}")

    async def generate_suggestions(self):
        try:
            history = await self.get_conversation_history()
            if len(history) < 2:
                return
            service = SmartReplyService()
            suggestions = await service.get_suggestions(
                self.room_id,
                self.user.id,
                history
            )
            if suggestions:
                await self.send(text_data=json.dumps({
                    'type': 'smart_replies',
                    'suggestions': suggestions
                }))
        except Exception as e:
            logger.error(f"Error generating suggestions: {e}")

    async def smart_replies(self, event):
        if event.get('target_user_id') == self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'smart_replies',
                'suggestions': event['suggestions']
            }))

    @database_sync_to_async
    def has_room_access(self):
        from apps.chat.models import ChatRoom
        try:
            room = ChatRoom.objects.get(id=self.room_id)
            return room.participants.filter(id=self.user.id).exists()
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def get_conversation_history(self):
        messages = Message.objects.filter(
            room_id=self.room_id
        ).select_related('sender').order_by('-created_at')[:10]
        history = []
        for msg in reversed(messages):
            if msg.sender:
                history.append(f"{msg.sender.username}: {msg.content[:100]}")
        return history
