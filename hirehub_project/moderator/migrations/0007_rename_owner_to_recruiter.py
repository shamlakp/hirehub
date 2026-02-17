from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('moderator', '0006_jobpost_no_of_vacancies'),
    ]

    operations = [
        migrations.RenameField(
            model_name='companyprofile',
            old_name='owner_name',
            new_name='recruiter_name',
        ),
        migrations.RenameField(
            model_name='companyprofile',
            old_name='owner_contact',
            new_name='recruiter_contact',
        ),
    ]
