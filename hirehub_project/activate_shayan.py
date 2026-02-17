
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hirehub_project.settings')
django.setup()

from adminpanel.models import CustomUser

def activate_user(username):
    try:
        user = CustomUser.objects.get(username=username)
        if not user.is_active:
            user.is_active = True
            user.save()
            print(f"User '{username}' activated successfully.")
        else:
            print(f"User '{username}' is already active.")
            
        # Also let's set a known password if needed, but user probably knows it.
        # Let's verify email too just in case
        print(f"Email: {user.email}")
        
    except CustomUser.DoesNotExist:
        print(f"User '{username}' not found.")
    except Exception as e:
        print(f"Error activating user '{username}': {e}")

if __name__ == '__main__':
    activate_user("Shayan")
