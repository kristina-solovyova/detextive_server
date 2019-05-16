import datetime
import time
from django.db import models
from django.utils import timezone
from django.contrib.auth.models import User


def get_file_path(instance, filename):
    ext = filename.split('.')[-1]
    user_id = instance.user.id
    milli_sec = int(round(time.time() * 1000))
    return "images/user_%s/%s.%s" % (user_id, milli_sec, ext)


class Image(models.Model):
    # Fields
    img = models.ImageField(upload_to=get_file_path, max_length=200)
    user = models.ForeignKey(User, related_name='images', on_delete=models.CASCADE)

    # Metadata
    class Meta:
        db_table = "images"

    # Methods
    def __str__(self):
        return str(self.id) + ': ' + self.img.path


class Result(models.Model):
    # Fields
    datetime = models.DateTimeField(auto_now_add=True)
    text = models.TextField(null=True, blank=True)
    image = models.OneToOneField(Image, related_name='result', on_delete=models.SET_NULL, null=True)
    user = models.ForeignKey(User, related_name='results', on_delete=models.CASCADE)

    # Metadata
    class Meta:
        ordering = ["-datetime"]
        db_table = "results"

    # Methods
    def __str__(self):
        return "%s results: %s" % (self.image.img.name, self.text)

    def saved_recently(self):
        return self.datetime >= timezone.now() - datetime.timedelta(days=1)


class ContactUs(models.Model):
    # Fields
    name = models.CharField(max_length=255, default='', blank=True)
    email = models.EmailField()
    subject = models.CharField(max_length=255)
    message = models.TextField()
    created = models.DateTimeField(auto_now_add=True)

    # Metadata
    class Meta:
        ordering = ["-created"]
        db_table = "contact_us"

    # Methods
    def __str__(self):
        return str(self.email) + ': ' + self.subject
