from celery import shared_task
import asyncio
from channels.layers import get_channel_layer
from .services import SmartReplyService
from apps.chat.models import Message
import logging

logger = logging.getLogger(__name__)

@shared_task
def generate_smart_replies(room_id, user_id):
    try:
        messages = Message.objects.filter(
            room_id=room_id
        ).select_related('sender').order_by('-created_at')[:8]
        
        if len(messages) < 2:
            return
        
        history = []
        for msg in reversed(messages):
            if msg.sender:
                history.append(f"{msg.sender.username}: {msg.content[:100]}")
        
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
        
        loop.close()
        
    except Exception as e:
        logger.error(f"Smart reply generation failed: {e}")
