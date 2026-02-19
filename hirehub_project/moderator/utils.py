from django.urls import reverse
from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.conf import settings

def send_verification_email(user):
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    verification_link = f"{settings.DOMAIN}/verify/{uid}/{token}/"
    
    send_mail(
        subject='Verify your HireHub account',
        message=f'Hi {user.username}, click the link to verify your account:\n{verification_link}',
        from_email=getattr(settings, 'EMAIL_HOST_USER', 'noreply@hirehub.com'),
        recipient_list=[user.email],
        fail_silently=True,
    )

def get_dashboard_url(user):
    dashboard_map = {
        'admin': 'adminpanel:admin_dashboard',
        'recruiter': 'moderator:company_dashboard',
    }
    return reverse(dashboard_map.get(user.user_type, 'unauthorized'))

def notify_admin_on_login(user):
    from django.core.mail import send_mail
    from django.conf import settings
    
    # We send the notification to the host email itself
    admin_email = getattr(settings, 'EMAIL_HOST_USER', '')
    if admin_email:
        send_mail(
            subject=f'Login Alert: {user.username}',
            message=f'User {user.username} ({user.user_type}) has just logged into HireHub.',
            from_email=admin_email,
            recipient_list=[admin_email],
            fail_silently=True,
        )
