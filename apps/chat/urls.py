from django.urls import path
from . import views

urlpatterns = [
    path('rooms/', views.RoomListView.as_view(), name='room-list'),
    path('rooms/create/', views.RoomCreateView.as_view(), name='room-create'),
    path('rooms/<uuid:pk>/', views.RoomDetailView.as_view(), name='room-detail'),
    path('rooms/<uuid:room_id>/messages/', views.RoomMessagesView.as_view(), name='room-messages'),
    path('rooms/<uuid:room_id>/mark-read/', views.MarkMessagesReadView.as_view(), name='mark-read'),
]

