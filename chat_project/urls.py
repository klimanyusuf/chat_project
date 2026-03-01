from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/chat/', include('apps.chat.urls')),
    path('', TemplateView.as_view(template_name='index.html'), name='dashboard'),
    path('room/<uuid:room_id>/', TemplateView.as_view(template_name='chat/room.html'), name='chat-room'),
    path('group-info/<uuid:room_id>/', TemplateView.as_view(template_name='group_info.html'), name='group-info'),
    path('login/', TemplateView.as_view(template_name='auth/login.html'), name='login'),
    path('signup/', TemplateView.as_view(template_name='auth/signup.html'), name='signup'),
    path('forgot-password/', TemplateView.as_view(template_name='auth/forgot_password.html'), name='forgot-password'),
    path('reset-password/<uidb64>/<token>/', TemplateView.as_view(template_name='auth/reset_password.html'), name='reset-password'),

]


