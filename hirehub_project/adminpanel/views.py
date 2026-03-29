import logging
from django.shortcuts import render,redirect,get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from django.contrib.auth.decorators import login_required
from rest_framework.permissions import AllowAny
from .serializers import CustomUserSerializer, PlatformSettingsSerializer
from .models import CustomUser, PlatformSettings, OTPVerification
logger = logging.getLogger(__name__)
from django.core.mail import send_mail
from django.conf import settings
from .decorators import admin_required
from django.urls import reverse
from django.http import JsonResponse
from moderator.models import JobPost, CompanyProfile, ApplicantProfile, JobApplication
from moderator.forms import JobPostForm, CompanyProfileForm
import json
import logging
from django.db import transaction, IntegrityError
from django.db.models import ProtectedError

logger = logging.getLogger(__name__)

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
    try:
        company = get_object_or_404(CompanyProfile, id=company_id)
        company.delete()
        return JsonResponse({'success': True})
    except Exception as e:
        return JsonResponse({'success': False, 'error': str(e)})

@csrf_exempt
@login_required
@admin_required
def ajax_delete_user(request, user_id):
    redirect_url = '/admin/adminpanel/customuser/'
    
    if request.method in ['POST', 'GET']:
        try:
            with transaction.atomic():
                target_user = get_object_or_404(CustomUser, id=user_id)
                
                if target_user == request.user:
                    error_msg = 'You cannot delete yourself.'
                    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                        return JsonResponse({'success': False, 'error': error_msg})
                    return redirect(redirect_url)

                # Explicitly handle related objects if needed, although CASCADE should work
                # Deleting the user will trigger CASCADE on CompanyProfile and ApplicantProfile
                target_user.delete()
                
                if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                    return JsonResponse({'success': True})
                return redirect(redirect_url)
                
        except ProtectedError as e:
            error_msg = f"Cannot delete user: {str(e)}"
            logger.error(f"ProtectedError deleting user {user_id}: {e}")
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return JsonResponse({'success': False, 'error': error_msg})
            return redirect(redirect_url)
        except IntegrityError as e:
            error_msg = f"Database integrity error: {str(e)}"
            logger.error(f"IntegrityError deleting user {user_id}: {e}")
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return JsonResponse({'success': False, 'error': error_msg})
            return redirect(redirect_url)
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(f"Error deleting user {user_id}: {e}")
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return JsonResponse({'success': False, 'error': error_msg})
            return redirect(redirect_url)
            
    return JsonResponse({'success': False, 'error': 'Invalid request method.'})



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

class SendOTPAPI(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if email is already registered
        if CustomUser.objects.filter(email=email).exists():
            return Response({'error': 'Email is already registered.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj, created = OTPVerification.objects.get_or_create(email=email)
        otp_obj.generate_otp()
        try:
            send_mail(
                subject='MEZBAN MANPOWER Registration OTP',
                message=f'Your verification code is: {otp_obj.otp}\nThis code will expire in 10 minutes.',
                from_email=getattr(settings, 'EMAIL_HOST_USER', 'noreply@mezbanmanpower.com'),
                recipient_list=[email],
                fail_silently=False, # Set to False to catch errors
            )
            logger.info(f"OTP successfully sent to {email}")
        except Exception as e:
            logger.error(f"Failed to send OTP email to {email}: {str(e)}")
            # In production, we want to know why it failed, but maybe not expose SMTP details to user
            return Response({'error': f'Failed to send email. Please contact support. (Ref: {type(e).__name__})'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({'message': 'OTP sent successfully to your email.'}, status=status.HTTP_200_OK)

class VerifyOTPAPI(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        
        if not email or not otp:
            return Response({'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)
            
        otp_obj = OTPVerification.objects.filter(email=email).first()
        if not otp_obj:
            return Response({'error': 'No OTP found for this email.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if not otp_obj.is_valid():
            return Response({'error': 'OTP has expired.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if otp_obj.otp != otp:
            return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)
            
        otp_obj.is_verified = True
        otp_obj.save()
        return Response({'message': 'Email verified successfully.'}, status=status.HTTP_200_OK)

class RegisterAPI(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        if email:
            otp_obj = OTPVerification.objects.filter(email=email).first()
            if not otp_obj or not otp_obj.is_verified:
                return Response({"error": "Please verify your email with an OTP first."}, status=status.HTTP_400_BAD_REQUEST)

        # We use a dedicated recruiter serializer to ensure password hashing and correct user_type
        from .serializers import RecruiterRegisterSerializer
        serializer = RecruiterRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = True # Auto-activate for testing
            user.save()
            # Clean up the OTP entry
            if email and otp_obj:
                otp_obj.delete()
            return Response({"message": "Registration successful. You can log in immediately."}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PlatformSettingsAPI(APIView):
    def get(self, request):
        settings = PlatformSettings.objects.first()
        if not settings:
            # Create default settings if none exist
            settings = PlatformSettings.objects.create()
        serializer = PlatformSettingsSerializer(settings)
        return Response(serializer.data)
