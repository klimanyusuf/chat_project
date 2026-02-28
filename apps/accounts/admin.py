from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ['email', 'username', 'is_online', 'last_seen', 'is_active']
    list_filter = ['is_online', 'is_active', 'date_joined']
    search_fields = ['email', 'username']
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('is_online', 'last_seen', 'avatar', 'bio')}),
    )
