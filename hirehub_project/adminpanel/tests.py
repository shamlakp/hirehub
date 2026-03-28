from django.test import TestCase, Client
from django.urls import reverse
from adminpanel.models import CustomUser, OTPVerification
from rest_framework.test import APIClient
from rest_framework import status

class AdminPanelAPITest(TestCase):
    def setUp(self):
        self.api_client = APIClient()
        self.client = Client()

    def test_register_api_creates_inactive_user(self):
        url = reverse('adminpanel:api_register')
        data = {
            'username': 'newuser',
            'email': 'new@example.com',
            'password': 'password123',
            'user_type': 'applicant'
        }
        # Create verified OTP record
        OTPVerification.objects.create(email='new@example.com', otp='123456', is_verified=True)
        
        response = self.api_client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('Registration successful', response.data['message'])
        
        user = CustomUser.objects.get(username='newuser')
        self.assertTrue(user.is_active)

    def test_login_api_fails_for_unverified_user(self):
        # Create inactive user
        user = CustomUser.objects.create_user(
            username='unverified',
            email='unverified@example.com',
            password='password123',
            is_active=False
        )
        
        url = reverse('adminpanel:api_login')
        data = {
            'username': 'unverified',
            'password': 'password123'
        }
        response = self.api_client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(response.data['error'], 'Please verify your email before logging in.')

    def test_login_api_succeeds_for_verified_user(self):
        # Create active user
        user = CustomUser.objects.create_user(
            username='verified',
            email='verified@example.com',
            password='password123',
            is_active=True
        )
        
        url = reverse('adminpanel:api_login')
        data = {
            'username': 'verified',
            'password': 'password123'
        }
        response = self.api_client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)

    def test_admin_can_delete_user(self):
        # Create admin user
        admin_user = CustomUser.objects.create_user(
            username='admin_user',
            email='admin@example.com',
            password='password123',
            user_type='admin',
            is_active=True,
            is_staff=True
        )
        self.api_client.force_authenticate(user=admin_user)
        self.client.force_login(admin_user)
        
        # Create target user
        target_user = CustomUser.objects.create_user(
            username='target_user',
            email='target@example.com',
            password='password123',
            user_type='recruiter'
        )
        
        url = reverse('adminpanel:ajax_delete_user', kwargs={'user_id': target_user.id})
        # Use standard Client which handles HTTP_XX headers better for standard views
        response = self.client.post(url, HTTP_X_REQUESTED_WITH='XMLHttpRequest')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()['success'])
        self.assertFalse(CustomUser.objects.filter(id=target_user.id).exists())

    def test_admin_cannot_delete_self(self):
        admin_user = CustomUser.objects.create_user(
            username='admin_user_self',
            email='admin_self@example.com',
            password='password123',
            user_type='admin',
            is_active=True
        )
        self.api_client.force_authenticate(user=admin_user)
        self.client.force_login(admin_user)
        
        url = reverse('adminpanel:ajax_delete_user', kwargs={'user_id': admin_user.id})
        response = self.client.post(url, HTTP_X_REQUESTED_WITH='XMLHttpRequest')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.json()['success'])
        self.assertEqual(response.json()['error'], 'You cannot delete yourself.')
        self.assertTrue(CustomUser.objects.filter(id=admin_user.id).exists())
