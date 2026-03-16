from django.db import models
from adminpanel.models import CustomUser
from django.utils import timezone


class CompanyProfile(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='companies')
    company_name = models.CharField(max_length=255, blank=True)
    head_office_address = models.TextField(blank=True)
    contact_number = models.CharField(max_length=20, blank=True)
    recruiter_name = models.CharField(max_length=255, blank=True)
    recruiter_contact = models.CharField(max_length=20, blank=True)
    website = models.URLField(blank=True)
    logo = models.ImageField(upload_to='logos/', blank=True)
    partner_name = models.CharField(max_length=100, blank=True)
    partner_contact = models.CharField(max_length=20, blank=True)
    supervisor_name = models.CharField(max_length=100, blank=True)
    supervisor_contact = models.CharField(max_length=20, blank=True)

    def __str__(self):
        return self.company_name


class ApplicantProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='applicant_profile')
    phone = models.CharField(max_length=20, blank=True)
    resume = models.FileField(upload_to='resumes/', blank=True)
    bio = models.TextField(blank=True)
    skills = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return f"{self.user.username} Profile"


from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=CustomUser)
def create_user_profiles(sender, instance, created, **kwargs):
    """Automatically create default profiles when a new user is created."""
    if created:
        if instance.user_type == 'applicant':
            ApplicantProfile.objects.get_or_create(user=instance)
        elif instance.user_type == 'recruiter':
            # Create a default company for new recruiters
            if not CompanyProfile.objects.filter(user=instance).exists():
                CompanyProfile.objects.create(
                    user=instance,
                    company_name=f"{instance.username} Company"
                )


class JobPost(models.Model):
    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE)
    created_at = models.DateTimeField(default=timezone.now)
    position = models.CharField(max_length=255)
    no_of_vacancies = models.PositiveIntegerField(default=1)
    location = models.CharField(max_length=100, blank=True)
    responsibilities = models.TextField(blank=True)
    qualifications = models.TextField(blank=True)
    industry = models.CharField(max_length=100, blank=True)
    accommodation = models.CharField(max_length=100, blank=True)
    meals = models.CharField(max_length=100, blank=True)
    category = models.CharField(max_length=100, blank=True)
    working_time = models.CharField(max_length=100)
    working_days = models.CharField(max_length=100)
    salary = models.CharField(max_length=100, blank=True)
    annual_leave = models.IntegerField(default=0)
    benefits = models.TextField(blank=True)
    is_approved = models.BooleanField(default=False)
    image = models.ImageField(upload_to='job_images/', blank=True, null=True)

    def __str__(self):
        return f"{self.position} at {self.company.company_name}"


class JobApplication(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('shortlisted', 'Shortlisted'),
        ('rejected', 'Rejected'),
    )
    job = models.ForeignKey(JobPost, on_delete=models.CASCADE, related_name='applications')
    applicant = models.ForeignKey(ApplicantProfile, on_delete=models.CASCADE, related_name='applications')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    applied_at = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)
    resume = models.FileField(upload_to='application_resumes/', blank=True, null=True)

    class Meta:
        unique_together = ('job', 'applicant')
        ordering = ['-applied_at']

    def __str__(self):
        return f"{self.applicant.user.username} - {self.job.position}"
