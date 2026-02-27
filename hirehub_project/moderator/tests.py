from django.test import TestCase, Client, override_settings
from django.urls import reverse
from adminpanel.models import CustomUser
from .models import CompanyProfile
from rest_framework.test import APIClient

@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
class UserFlowsTest(TestCase):
    def setUp(self):
        self.client = Client()

    def test_applicant_registration_creates_applicant_user(self):
        url = reverse('moderator:applicant_register')
        data = {
            'username': 'applicant1',
            'email': 'app1@example.com',
            'password': 'testpass123',
            'confirm_password': 'testpass123',
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, 302)  # redirect to login
        user = CustomUser.objects.get(username='applicant1')
        self.assertEqual(user.user_type, 'applicant')
        # Applicants are now inactive pending email verification
        self.assertFalse(user.is_active)

    def test_recruiter_registration_creates_inactive_recruiter(self):
        url = reverse('moderator:company_register')
        data = {
            'username': 'recruiter1',
            'email': 'rec1@example.com',
            'password': 'testpass123',
            'confirm_password': 'testpass123',
        }
        response = self.client.post(url, data)
        # expects redirect after registration
        self.assertEqual(response.status_code, 302)
        user = CustomUser.objects.get(username='recruiter1')
        self.assertEqual(user.user_type, 'recruiter')
        # company_register creates inactive user pending email verification
        self.assertFalse(user.is_active)

    def test_recruiter_can_create_company(self):
        # create recruiter user and login
        user = CustomUser.objects.create_user(username='rec2', email='rec2@example.com', password='testpass', user_type='recruiter')
        self.client.login(username='rec2', password='testpass')
        url = reverse('moderator:create_company')
        data = {
            'user': user.id,
            'company_name': 'TestCo',
            'recruiter_contact': '0123456789',
            'head_office_address': '123 Main St',
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, 302)
        # The view now updates the existing profile created by the signal
        company = CompanyProfile.objects.get(user=user)
        self.assertEqual(company.company_name, 'TestCo')

    def test_applicant_cannot_create_company(self):
        user = CustomUser.objects.create_user(username='app2', email='app2@example.com', password='testpass', user_type='applicant')
        self.client.login(username='app2', password='testpass')
        url = reverse('moderator:create_company')
        response = self.client.get(url)
        # redirected to company_dashboard because applicant cannot create company
        self.assertEqual(response.status_code, 302)

    def test_applicant_api_registration(self):
        url = reverse('moderator:api_applicant_register')
        data = {
            'username': 'api_app',
            'email': 'apiapp@example.com',
            'password': 'testpass123'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, 201)
        user = CustomUser.objects.get(username='api_app')
        self.assertEqual(user.user_type, 'applicant')
        # API registrations also create inactive users
        self.assertFalse(user.is_active)

    def test_applicant_profile_get_and_patch(self):
        # create applicant and token
        user = CustomUser.objects.create_user(username='appr', email='appr@example.com', password='pw', user_type='applicant')
        from rest_framework.authtoken.models import Token
        token = Token.objects.create(user=user)
        url = reverse('moderator:api_applicant_profile')
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)

        # GET -> empty/default profile
        response = client.get(url)
        self.assertEqual(response.status_code, 200)

        # PATCH -> update phone and bio
        response = client.patch(url, {'phone': '012345', 'bio': 'Hello'}, format='multipart')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['phone'], '012345')
        self.assertEqual(response.data['bio'], 'Hello')

    def test_applicant_can_apply_to_job(self):
        # Create recruiter and job
        recruiter_user = CustomUser.objects.create_user(username='rec3', email='rec3@example.com', password='pw', user_type='recruiter')
        from .models import CompanyProfile, JobPost, ApplicantProfile, JobApplication
        # Signal creates profile, we just need to use/update it
        company = CompanyProfile.objects.get(user=recruiter_user)
        company.company_name = 'RecCo'
        company.save()
        
        job = JobPost.objects.create(company=company, position='Developer', working_time='Full Time', working_days='Mon-Fri')
        
        # Create applicant and token
        applicant_user = CustomUser.objects.create_user(username='appa', email='appa@example.com', password='pw', user_type='applicant')
        # Signal creates profile automatically
        applicant_profile = ApplicantProfile.objects.get(user=applicant_user)
        
        from rest_framework.authtoken.models import Token
        token = Token.objects.create(user=applicant_user)
        
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)
        
        # Apply for job
        url = reverse('moderator:jobapplication-list')
        response = client.post(url, {'job': job.id, 'notes': 'My cover letter'})
        self.assertEqual(response.status_code, 201)
        
        # Check duplicate (should fail with 400)
        response = client.post(url, {'job': job.id})
        self.assertEqual(response.status_code, 400)

    def test_recruiter_can_update_application_status(self):
        # Setup
        recruiter_user = CustomUser.objects.create_user(username='rec4', email='rec4@example.com', password='pw', user_type='recruiter')
        from .models import CompanyProfile, JobPost, ApplicantProfile, JobApplication
        company = CompanyProfile.objects.get(user=recruiter_user)
        job = JobPost.objects.create(company=company, position='Dev')
        
        applicant_user = CustomUser.objects.create_user(username='appb', email='appb@example.com', password='pw', user_type='applicant')
        applicant_profile = ApplicantProfile.objects.get(user=applicant_user)
        
        application = JobApplication.objects.create(job=job, applicant=applicant_profile, status='pending')
        
        # Recruiter login
        from rest_framework.authtoken.models import Token
        token = Token.objects.create(user=recruiter_user)
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)
        
        # Update status
        url = reverse('moderator:jobapplication-detail', kwargs={'pk': application.id})
        response = client.patch(url, {'status': 'shortlisted'})
        self.assertEqual(response.status_code, 200)
        application.refresh_from_db()
        self.assertEqual(application.status, 'shortlisted')

    def test_applicant_cannot_update_application_status(self):
        # Setup
        recruiter_user = CustomUser.objects.create_user(username='rec5', email='rec5@example.com', password='pw', user_type='recruiter')
        from .models import CompanyProfile, JobPost, ApplicantProfile, JobApplication
        company = CompanyProfile.objects.get(user=recruiter_user)
        job = JobPost.objects.create(company=company, position='Dev')
        
        applicant_user = CustomUser.objects.create_user(username='appc', email='appc@example.com', password='pw', user_type='applicant')
        applicant_profile = ApplicantProfile.objects.get(user=applicant_user)
        
        application = JobApplication.objects.create(job=job, applicant=applicant_profile, status='pending')
        
        # Applicant login
        from rest_framework.authtoken.models import Token
        token = Token.objects.create(user=applicant_user)
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)
        
        # Attempt update status (should fail with 403 PermissionDenied)
        url = reverse('moderator:jobapplication-detail', kwargs={'pk': application.id})
        response = client.patch(url, {'status': 'shortlisted'})
        self.assertEqual(response.status_code, 403)
        application.refresh_from_db()
        self.assertEqual(application.status, 'pending')


