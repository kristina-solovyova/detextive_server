import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'detextive_server.settings')

app = Celery('detextive_server')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
