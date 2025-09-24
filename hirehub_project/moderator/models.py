from django.db import models
from adminpanel.models import CustomUser
from django.utils import timezone


class CompanyProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    company_name = models.CharField(max_length=255)
    head_office_address = models.TextField()
    contact_number = models.CharField(max_length=20)
    owner_name = models.CharField(max_length=255)
    owner_contact = models.CharField(max_length=20)
    website = models.URLField(blank=True)
    logo = models.ImageField(upload_to='logos/', blank=True)
    partner_name = models.CharField(max_length=100, blank=True)
    partner_contact = models.CharField(max_length=20, blank=True)
    supervisor_name = models.CharField(max_length=100, blank=True)
    supervisor_contact = models.CharField(max_length=20, blank=True)

    def __str__(self):
        return self.company_name

class JobPost(models.Model):
    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE)
    created_at = models.DateTimeField(default=timezone.now)
    title = models.CharField(max_length=255)
    responsibilities = models.TextField(blank=True)
    qualifications = models.TextField(blank=True)
    working_time = models.CharField(max_length=100)
    working_days = models.CharField(max_length=100)
    salary = models.CharField(max_length=100, blank=True)
    annual_leave = models.IntegerField(default=0)
    benefits = models.TextField(blank=True)
    is_approved = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.title} at {self.company.company_name}"


# Create your models here.
