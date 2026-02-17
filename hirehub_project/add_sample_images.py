"""
Script to add sample placeholder images to jobs for testing
Run this with: python add_sample_images.py
"""
import os
import django
import requests
from io import BytesIO
from PIL import Image

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hirehub_project.settings')
django.setup()

from moderator.models import JobPost
from django.core.files.base import ContentFile

def download_placeholder_image(width=800, height=450, text="Job"):
    """Download a placeholder image from placeholder service"""
    url = f"https://via.placeholder.com/{width}x{height}/0D47A1/FFFFFF?text={text.replace(' ', '+')}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return BytesIO(response.content)
    except Exception as e:
        print(f"Error downloading image: {e}")
    return None

def add_images_to_jobs():
    """Add placeholder images to all jobs without images"""
    jobs = JobPost.objects.filter(image__isnull=True) | JobPost.objects.filter(image='')
    
    print(f"Found {jobs.count()} jobs without images")
    
    for job in jobs:
        print(f"Adding image to: {job.position}")
        
        # Download placeholder image
        image_data = download_placeholder_image(text=job.position[:20])
        
        if image_data:
            # Save the image to the job
            filename = f"{job.position.replace(' ', '_').lower()}_{job.id}.jpg"
            job.image.save(filename, ContentFile(image_data.getvalue()), save=True)
            print(f"  ✓ Image added: {job.image.url}")
        else:
            print(f"  ✗ Failed to download image")
    
    print("\nDone!")

if __name__ == "__main__":
    add_images_to_jobs()
