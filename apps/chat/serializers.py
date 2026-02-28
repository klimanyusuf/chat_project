from rest_framework import serializers
from .models import ChatRoom, Message, MessageReadReceipt, MessageDeliveryReceipt
from apps.accounts.serializers import UserSerializer

class ChatRoomSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    participant_ids = serializers.ListField(write_only=True, child=serializers.IntegerField())
    created_by = UserSerializer(read_only=True)
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = ['id', 'name', 'room_type', 'participants', 'participant_ids',
                  'created_by', 'created_at', 'last_message_at', 'last_message']
        read_only_fields = ['id', 'created_at', 'last_message_at']

    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return {
                'id': str(last_msg.id),
                'content': last_msg.content[:50],
                'sender': last_msg.sender.username,
                'timestamp': last_msg.created_at.isoformat()
            }
        return None

    def create(self, validated_data):
        participant_ids = validated_data.pop('participant_ids')
        room = ChatRoom.objects.create(**validated_data)
        if validated_data.get('created_by'):
            if validated_data['created_by'].id not in participant_ids:
                participant_ids.append(validated_data['created_by'].id)
        room.participants.set(participant_ids)
        return room

class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    read_by = serializers.SerializerMethodField()
    delivered_to = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ['id', 'room', 'sender', 'content', 'message_type', 'created_at',
                  'read_by', 'delivered_to', 'status']

    def get_read_by(self, obj):
        return [receipt.user.username for receipt in obj.read_receipts.all()]

    def get_delivered_to(self, obj):
        return [receipt.user.username for receipt in obj.delivery_receipts.all()]

    def get_status(self, obj):
        request = self.context.get('request')
        if request and request.user:
            user = request.user
            if obj.read_receipts.filter(user=user).exists():
                return 'read'
            elif obj.delivery_receipts.filter(user=user).exists():
                return 'delivered'
            else:
                return 'sent'
        return 'sent'
