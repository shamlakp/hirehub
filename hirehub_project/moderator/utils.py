from django.urls import reverse

def get_dashboard_url(user):
    dashboard_map = {
        'admin': 'adminpanel:admin_dashboard',
        'recruiter': 'moderator:recruiter_dashboard',
    }
    try:
        return reverse(dashboard_map[user.user_type])
    except KeyError:
        raise ValueError(f"Unknown user type: {user.user_type}")
