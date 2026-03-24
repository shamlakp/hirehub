from django.contrib.auth.models import AbstractUser
from django.db import models
from django.urls import reverse
from django.utils import timezone
import random

class CustomUser(AbstractUser):
    USER_TYPES = (
        ('admin', 'Admin'),
        ('recruiter', 'Recruiter'),
        ('applicant', 'Applicant'),
    )
    user_type = models.CharField(max_length=10, default='recruiter')
    email = models.EmailField(unique=True)

    def __str__(self):
        return f"{self.username} ({self.user_type})"


class PlatformSettings(models.Model):
    phone_number = models.CharField(max_length=20, default="+91 0000000000")
    whatsapp_number = models.CharField(max_length=20, default="+91 0000000000")
    email = models.EmailField(default="contact@mezbanmanpower.com")
    address = models.TextField(blank=True)
    whatsapp_link = models.URLField(blank=True, help_text="Direct link for WhatsApp chat")

    class Meta:
        verbose_name = "Platform Settings"
        verbose_name_plural = "Platform Settings"

    def __str__(self):
        return "Platform Global Settings"

class OTPVerification(models.Model):
    email = models.EmailField(unique=True)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_verified = models.BooleanField(default=False)

    def is_valid(self):
        # OTP is valid for 10 minutes
        delta = timezone.now() - self.created_at
        return delta.total_seconds() < 600

    def generate_otp(self):
        self.otp = str(random.randint(100000, 999999))
        self.created_at = timezone.now()
        self.is_verified = False
        self.save()
