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
        company = CompanyProfile.objects.get(company_name='TestCo')
        self.assertEqual(company.user, user)

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


