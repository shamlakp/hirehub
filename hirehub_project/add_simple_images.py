"""
Script to add simple colored placeholder images to jobs
Run this with: python add_simple_images.py
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hirehub_project.settings')
django.setup()

from moderator.models import JobPost
from django.core.files.base import ContentFile
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO

def create_placeholder_image(text, width=800, height=450, bg_color=(13, 71, 161), text_color=(255, 255, 255)):
    """Create a simple placeholder image with text"""
    # Create image
    img = Image.new('RGB', (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Try to use a font, fall back to default if not available
    try:
        font = ImageFont.truetype("arial.ttf", 60)
    except:
        font = ImageFont.load_default()
    
    # Calculate text position (center)
    text = text[:30]  # Limit text length
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    position = ((width - text_width) // 2, (height - text_height) // 2)
    
    # Draw text
    draw.text(position, text, fill=text_color, font=font)
    
    # Save to BytesIO
    buffer = BytesIO()
    img.save(buffer, format='JPEG', quality=85)
    buffer.seek(0)
    
    return buffer

def add_images_to_jobs():
    """Add placeholder images to all jobs without images"""
    jobs = JobPost.objects.filter(image__isnull=True) | JobPost.objects.filter(image='')
    
    print(f"Found {jobs.count()} jobs without images\n")
    
    colors = [
        (13, 71, 161),   # Blue
        (76, 175, 80),   # Green
        (255, 152, 0),   # Orange
        (156, 39, 176),  # Purple
        (244, 67, 54),   # Red
    ]
    
    for idx, job in enumerate(jobs):
        print(f"Adding image to: {job.position}")
        
        # Use different colors for variety
        color = colors[idx % len(colors)]
        
        # Create placeholder image
        image_buffer = create_placeholder_image(job.position, bg_color=color)
        
        # Save the image to the job
        filename = f"{job.position.replace(' ', '_').lower()}_{job.id}.jpg"
        job.image.save(filename, ContentFile(image_buffer.getvalue()), save=True)
        print(f"  ✓ Image added: {job.image.url}\n")
    
    print("Done! All jobs now have images.")

if __name__ == "__main__":
    add_images_to_jobs()
