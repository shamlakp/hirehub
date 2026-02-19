from django.shortcuts import render,redirect,get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from django.contrib.auth.decorators import login_required
from .serializers import CustomUserSerializer, PlatformSettingsSerializer
from .models import CustomUser, PlatformSettings
from .decorators import admin_required
from django.urls import reverse
from django.http import JsonResponse
from moderator.models import JobPost, CompanyProfile
from moderator.forms import JobPostForm, CompanyProfileForm
import json

@login_required
@admin_required
def admin_dashboard(request):
    jobs = JobPost.objects.all().order_by('-id')
    recruiters = CustomUser.objects.filter(user_type='recruiter')
    return render(request, 'adminpanel/dashboard.html', {
        'jobs': jobs,
        'recruiters': recruiters,
    })

@login_required
@admin_required
def approve_job(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    job.is_approved = True
    job.save()
    return redirect('adminpanel:admin_dashboard')


@login_required
@admin_required
def deactivate_job(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    job.is_approved = False
    job.save()
    return redirect('adminpanel:admin_dashboard') 


@login_required
def add_company(request):
    if request.user.user_type != 'admin':
        return redirect('adminpanel:admin_dashboard')

    form = CompanyProfileForm(request.POST or None, request.FILES or None)
    if request.method == 'POST' and form.is_valid():
        form.save()
        return redirect('adminpanel:manage_companies')

    return render(request, 'adminpanel/add_company.html', {'form': form})


@login_required
def manage_companies(request):
    if request.user.user_type != 'admin':
        return redirect('adminpanel:admin_dashboard')

    companies = CompanyProfile.objects.select_related('user').order_by('company_name')
    return render(request, 'adminpanel/manage_companies.html', {'companies': companies})



@login_required
def manage_jobs(request):
    if request.user.user_type != 'admin':
        return redirect('adminpanel:admin_dashboard')

    jobs = JobPost.objects.select_related('company').order_by('-created_at')
    return render(request, 'adminpanel/manage_jobs.html', {'jobs': jobs})



@csrf_exempt
@login_required
def ajax_edit_company(request, company_id):
    data = json.loads(request.body)
    company = get_object_or_404(CompanyProfileForm, id=company_id)
    form = CompanyForm(data, instance=company)
    if form.is_valid():
        form.save()
        return JsonResponse({'success': True})
    return JsonResponse({'success': False, 'errors': form.errors})


@csrf_exempt
@login_required
def ajax_delete_company(request, company_id):
    company = get_object_or_404(CompanyProfile, id=company_id)
    company.delete()
    return JsonResponse({'success': True})



@csrf_exempt
@login_required
def ajax_edit_job(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    if request.method == 'POST' and request.user.user_type == 'admin':
        form = JobPostForm(request.POST, instance=job)
        if form.is_valid():
            form.save()
            return JsonResponse({'success': True})
        else:
            return JsonResponse({'success': False, 'errors': form.errors})
    return JsonResponse({'success': False, 'error': 'Invalid request'})



@csrf_exempt
@login_required
def ajax_delete_job(request, job_id):
    if request.method == 'POST' and request.user.user_type == 'admin':
        try:
            job = JobPost.objects.get(id=job_id)
            job.delete()
            return JsonResponse({'success': True})
        except JobPost.DoesNotExist:
            return JsonResponse({'success': False, 'error': 'Job not found'})
    return JsonResponse({'success': False, 'error': 'Invalid request'})


class LoginAPI(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user:
            token, created = Token.objects.get_or_create(user=user)
            from moderator.utils import notify_admin_on_login
            notify_admin_on_login(user)
            return Response({'status': 'success', 'user_type': user.user_type, 'username': user.username, 'token': token.key})
        
        # Check if user exists but is inactive
        user_check = CustomUser.objects.filter(username=username).first()
        if user_check and not user_check.is_active:
            return Response({'error': 'Please verify your email before logging in.'}, status=status.HTTP_401_UNAUTHORIZED)
            
        return Response({'error': 'Invalid Credentials'}, status=status.HTTP_400_BAD_REQUEST)

class RegisterAPI(APIView):
    def post(self, request):
        # We use a dedicated recruiter serializer to ensure password hashing and correct user_type
        from .serializers import RecruiterRegisterSerializer
        serializer = RecruiterRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = False # Require email verification
            user.save()
            from moderator.utils import send_verification_email
            send_verification_email(user)
            return Response({"message": "Registration successful. Please verify your email."}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PlatformSettingsAPI(APIView):
    def get(self, request):
        settings = PlatformSettings.objects.first()
        if not settings:
            # Create default settings if none exist
            settings = PlatformSettings.objects.create()
        serializer = PlatformSettingsSerializer(settings)
        return Response(serializer.data)
