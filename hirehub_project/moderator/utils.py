from django.urls import reverse

def get_dashboard_url(user):
    dashboard_map = {
        'admin': 'adminpanel:dashboard',
        'owner': 'moderator:company_dashboard',
    }
    return reverse(dashboard_map.get(user.user_type, 'unauthorized'))

