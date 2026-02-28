from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/chat/', include('apps.chat.urls')),
    path('', TemplateView.as_view(template_name='index.html'), name='dashboard'),
    path('room/<uuid:room_id>/', TemplateView.as_view(template_name='chat/room.html'), name='chat-room'),
]

