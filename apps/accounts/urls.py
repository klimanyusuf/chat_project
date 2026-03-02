from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('session/', views.SessionCheckView.as_view(), name='session-check'),
    path('refresh/', views.RefreshSessionView.as_view(), name='refresh'),
    path('users/', views.UserListView.as_view(), name='user-list'),
    path('forgot-password/', views.ForgotPasswordView.as_view(), name='forgot-password'),
]
