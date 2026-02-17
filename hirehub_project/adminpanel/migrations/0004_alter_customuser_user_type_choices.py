from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('adminpanel', '0003_convert_owner_to_recruiter'),
    ]

    operations = [
        migrations.AlterField(
            model_name='customuser',
            name='user_type',
            field=models.CharField(choices=[('admin', 'Admin'), ('recruiter', 'Recruiter'), ('applicant', 'Applicant')], max_length=10, default='recruiter'),
        ),
    ]
