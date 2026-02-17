from django.db import migrations


def forwards(apps, schema_editor):
    CustomUser = apps.get_model('adminpanel', 'CustomUser')
    CustomUser.objects.filter(user_type='owner').update(user_type='recruiter')


class Migration(migrations.Migration):

    dependencies = [
        ('adminpanel', '0002_alter_customuser_user_type'),
    ]

    operations = [
        migrations.RunPython(forwards),
    ]
