from django.contrib.auth.models import AbstractUser
from django.db import models
from django.urls import reverse

class CustomUser(AbstractUser):
    USER_TYPES = (
        ('admin', 'Admin'),
        ('owner', 'Owner'),
    )
    user_type = models.CharField(max_length=10, default='owner')
    email = models.EmailField(unique=True)

    def __str__(self):
        return f"{self.username} ({self.user_type})"



