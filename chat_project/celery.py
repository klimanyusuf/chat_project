import os
from celery import Celery
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_project.settings')

app = Celery('chat_project')
app.config_from_object('django.conf:settings', namespace='CELERY')

# Debug: print broker URL after configuration
print(f"Celery broker URL from settings: {settings.CELERY_BROKER_URL}")
print(f"Celery app broker URL: {app.conf.broker_url}")

app.autodiscover_tasks()