from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('moderator', '0007_rename_owner_to_recruiter'),
    ]

    operations = [
        migrations.CreateModel(
            name='ApplicantProfile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('phone', models.CharField(blank=True, max_length=20)),
                ('resume', models.FileField(blank=True, upload_to='resumes/')),
                ('bio', models.TextField(blank=True)),
                ('skills', models.CharField(blank=True, max_length=255)),
                ('user', models.OneToOneField(on_delete=models.deletion.CASCADE, to='adminpanel.customuser')),
            ],
        ),
    ]
