
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hirehub_project.settings')
django.setup()

from moderator.models import JobPost
from moderator.serializers import JobPostSerializer

def debug_jobs():
    print("Checking JobPosts...")
    try:
        jobs = JobPost.objects.all()
        print(f"Found {jobs.count()} jobs.")
        
        for job in jobs:
            print(f"Job ID: {job.id}")
            try:
                print(f"  Position: {job.position}")
                print(f"  Company: {job.company}")
                print(f"  Company Name: {job.company.company_name}")
                
                 # Try serialization
                serializer = JobPostSerializer(job)
                print(f"  Serialized: {serializer.data}")
                
            except Exception as e:
                print(f"  ERROR accessing job {job.id}: {e}")
                
    except Exception as e:
        print(f"Global Error: {e}")

if __name__ == '__main__':
    debug_jobs()
