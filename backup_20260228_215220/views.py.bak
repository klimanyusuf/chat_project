from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from .models import ChatRoom, Message, MessageReadReceipt, MessageDeliveryReceipt, RoomMembership
from .serializers import ChatRoomSerializer, MessageSerializer

class RoomListView(generics.ListAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatRoom.objects.filter(participants=self.request.user).order_by('-last_message_at')

class RoomCreateView(generics.CreateAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        room_type = serializer.validated_data.get('room_type')
        participant_ids = serializer.validated_data.get('participant_ids', [])

        if room_type == 'private' and len(participant_ids) == 1:
            other_user_id = participant_ids[0]
            existing_room = ChatRoom.objects.filter(
                room_type='private',
                participants=request.user
            ).filter(participants__id=other_user_id).first()
            if existing_room:
                response_serializer = self.get_serializer(existing_room)
                return Response(response_serializer.data, status=status.HTTP_200_OK)

        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        room = serializer.save(created_by=self.request.user)
        RoomMembership.objects.create(room=room, user=self.request.user, role='admin')
        participant_ids = serializer.validated_data.get('participant_ids', [])
        for uid in participant_ids:
            if uid != self.request.user.id:
                RoomMembership.objects.create(room=room, user_id=uid, role='member')

class RoomDetailView(generics.RetrieveAPIView):
    queryset = ChatRoom.objects.all()
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]

class RoomMessagesView(generics.ListAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        room_id = self.kwargs['room_id']
        return Message.objects.filter(room_id=room_id).order_by('created_at')

class RoomMembersView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, room_id):
        memberships = RoomMembership.objects.filter(room_id=room_id).select_related('user')
        data = [{
            'id': m.user.id,
            'username': m.user.username,
            'role': m.role,
            'joined_at': m.joined_at.isoformat()
        } for m in memberships]
        return Response(data)

class MarkMessagesReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, room_id):
        message_ids = request.data.get('message_ids', [])
        if not message_ids:
            messages = Message.objects.filter(room_id=room_id).exclude(read_receipts__user=request.user)
        else:
            messages = Message.objects.filter(id__in=message_ids, room_id=room_id).exclude(read_receipts__user=request.user)

        receipts = []
        for message in messages:
            receipt, created = MessageReadReceipt.objects.get_or_create(
                message=message,
                user=request.user,
                defaults={'read_at': timezone.now()}
            )
            if created:
                receipts.append(receipt)
        return Response({'marked': len(receipts)})
