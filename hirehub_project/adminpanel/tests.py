from django.test import TestCase, Client
from django.urls import reverse
from adminpanel.models import CustomUser
from rest_framework.test import APIClient
from rest_framework import status

class AdminPanelAPITest(TestCase):
    def setUp(self):
        self.api_client = APIClient()

    def test_register_api_creates_inactive_user(self):
        url = reverse('adminpanel:api_register')
        data = {
            'username': 'newuser',
            'email': 'new@example.com',
            'password': 'password123',
            'user_type': 'applicant'
        }
        response = self.api_client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('Please verify your email', response.data['message'])
        
        user = CustomUser.objects.get(username='newuser')
        self.assertFalse(user.is_active)

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
