from django.shortcuts import render, redirect, reverse, get_object_or_404
from django.http import HttpResponse 
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.conf import settings
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes
import logging

logger = logging.getLogger(__name__)

from .utils import get_dashboard_url, notify_admin_on_login
from .models import JobPost, CompanyProfile, ApplicantProfile, JobApplication 
from .forms import RecruiterForm, ApplicantForm, CompanyProfileForm, JobPostForm
from adminpanel.models import OTPVerification


def homepage(request):
    jobs = JobPost.objects.filter(is_approved=True)
    return render(request, 'homepage.html', {'jobs': jobs})


@login_required
def company_dashboard(request):
    company = CompanyProfile.objects.filter(user=request.user).first()
    jobs = JobPost.objects.filter(company=company).order_by('-id') if company else []
    return render(request, 'moderator/company_dashboard.html', {
        'company': company,
        'jobs': jobs
    })    



def public_job_list(request):
    jobs = JobPost.objects.filter(is_approved=True).order_by('-created_at')
    
    # If user is NOT logged in, show only top 3
    if not request.user.is_authenticated:
        jobs = jobs[:3]
        
    return render(request, 'moderator/public_jobs.html', {'jobs': jobs})


def job_detail(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    return render(request, 'moderator/job_detail.html', {'job': job})


User = get_user_model()
def company_register(request):
    if request.method == 'POST':
        form = RecruiterForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            username = form.cleaned_data['username']

            # 🔹 Delete inactive user with same email
            existing_user = User.objects.filter(email=email).first()
            if existing_user:
                if not existing_user.is_active:
                    existing_user.delete()
                else:
                    form.add_error('email', 'This email is already registered.')
                    return render(request, 'moderator/company_register.html', {'form': form})

            # 🔹 Check for existing username
            if User.objects.filter(username=username).exists():
                form.add_error('username', 'This username is already taken.')
                return render(request, 'moderator/company_register.html', {'form': form})

            # 🔹 Create active user
            user = form.save(commit=False)
            user.is_active = True
            user.save()

            # 🔹 Skip verification email since user is auto-activated
            # from .utils import send_verification_email
            # send_verification_email(user)

            return redirect('moderator:company_dashboard')
    else:
        form = RecruiterForm()
    return render(request, 'moderator/company_register.html', {'form': form})



def applicant_register(request):
    """Simple applicant (jobseeker) registration.
    Applicants are active immediately (no email verification by default).
    """
    if request.method == 'POST':
        form = ApplicantForm(request.POST)
        if form.is_valid():
            user = form.save()
            # from .utils import send_verification_email
            # send_verification_email(user)
            messages.success(request, "Registration successful. You can now log in.")
            return redirect('moderator:login')
    else:
        form = ApplicantForm()
    return render(request, 'moderator/applicant_register.html', {'form': form})





def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user :
            login(request, user)
            notify_admin_on_login(user)
            return redirect(get_dashboard_url(user))
        else :
            messages.error(request, "Invalid username or password.")   
    return render(request, 'moderator/login.html')       


def logout_view(request):
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect('moderator:homepage') 



def verify_email(request, uidb64, token):
    User = get_user_model()
    try:
        uid = urlsafe_base64_decode(uidb64).decode()
        user = User.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        user = None

    if user and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        messages.success(request, "Email verified successfully. You can now log in.")
        return redirect('moderator:login')
    else:
        return HttpResponse('Verification link is invalid or expired.')


@login_required
def create_company(request):
    # Only users with type 'recruiter' can access this
    if request.user.user_type != 'recruiter':
        return redirect('moderator:company_dashboard')

    # Get existing profile if it exists (e.g., created by signal)
    company = CompanyProfile.objects.filter(user=request.user).first()

    if request.method == 'POST':
        form = CompanyProfileForm(request.POST, request.FILES, instance=company)
        if form.is_valid():
            company = form.save(commit=False)
            company.user = request.user
            company.save()
            return redirect('moderator:company_dashboard')
    else:
        form = CompanyProfileForm(instance=company)

    return render(request, 'moderator/create_company.html', {'form': form, 'company': company})



@login_required
def create_job(request):
    company = CompanyProfile.objects.filter(user=request.user).first()
    if not company:
        return redirect('moderator:create_company')
    form = JobPostForm()
    if request.method == 'POST':
        form = JobPostForm(request.POST)
        if form.is_valid():
            job = form.save(commit=False)
            job.company = company
            job.save()
            return redirect('moderator:company_dashboard')
    return render(request, 'moderator/create_job.html', {'form': form})


from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError, PermissionDenied
from .serializers import CompanyProfileSerializer, JobPostSerializer, JobApplicationSerializer, ApplicantProfileSerializer
from adminpanel.serializers import ApplicantSerializer

@login_required
def edit_job(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    # Ensure user owns this job
    if job.company.user != request.user:
        return redirect('moderator:company_dashboard')
        
    if request.method == 'POST':
        form = JobPostForm(request.POST, instance=job)
        if form.is_valid():
            form.save()
            return redirect('moderator:company_dashboard')
    else:
        form = JobPostForm(instance=job)
        
    return render(request, 'moderator/edit_job.html', {'form': form, 'job': job})


@login_required
def delete_job(request, job_id):
    job = get_object_or_404(JobPost, id=job_id)
    # Ensure user owns this job
    if job.company.user == request.user:
        if request.method == 'POST':
            job.delete()
            
    return redirect('moderator:company_dashboard')



class CompanyViewSet(viewsets.ModelViewSet):
    queryset = CompanyProfile.objects.all()
    serializer_class = CompanyProfileSerializer
    parser_classes = [MultiPartParser, FormParser]

class JobPostViewSet(viewsets.ModelViewSet):
    queryset = JobPost.objects.all().order_by('-created_at')
    serializer_class = JobPostSerializer
    authentication_classes = [TokenAuthentication]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated()]
        return []

    def perform_create(self, serializer):
        print(f"DEBUG: JobPost create data: {self.request.data}")
        # Automatically assign the recruiter's company to the job post
        # If multiple companies, we should get the company_id from request data
        company_id = self.request.data.get('company')
        if not company_id:
            # Fallback to the first company if not specified (legacy behavior)
            company = CompanyProfile.objects.filter(user=self.request.user).first()
        else:
            company = CompanyProfile.objects.filter(id=company_id, user=self.request.user).first()

        if not company:
            raise ValidationError("You must choose a Company Profile you own before posting a job.")
        serializer.save(company=company)


class ApplicantRegisterAPI(APIView):
    def post(self, request):
        email = request.data.get('email')
        if email:
            otp_obj = OTPVerification.objects.filter(email=email).first()
            if not otp_obj or not otp_obj.is_verified:
                return Response({"error": "Please verify your email with an OTP first."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ApplicantSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = True
            user.save()
            if email and otp_obj:
                otp_obj.delete()
            return Response({"message": "Registration successful. You can log in immediately."}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LogoutAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # Clear Django session if exists (important for web)
            logout(request)
            
            # Delete DRF token safely
            if request.auth:
                request.auth.delete()
                
            return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            # Log the error for the developer but don't 500
            print(f"Logout Error: {e}")
            return Response({"error": "Logout failed or token already invalid"}, status=status.HTTP_400_BAD_REQUEST)


class ApplicantProfileAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        profile, _ = ApplicantProfile.objects.get_or_create(user=request.user)
        serializer = ApplicantProfileSerializer(profile)
        return Response(serializer.data)

    def patch(self, request):
        logger.debug(f"ApplicantProfile patch data: {request.data}")
        profile, _ = ApplicantProfile.objects.get_or_create(user=request.user)
        serializer = ApplicantProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            # Return updated data
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RecruiterProfileAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        companies = CompanyProfile.objects.filter(user=request.user)
        # If no companies exist, create a default one (fallback)
        if not companies.exists():
            default_company = CompanyProfile.objects.create(
                user=request.user,
                company_name=f"{request.user.username} Company"
            )
            companies = [default_company]
             
        serializer = CompanyProfileSerializer(companies, many=True)
        return Response(serializer.data)

    def post(self, request):
        """Create a new company profile for this recruiter."""
        serializer = CompanyProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        """Update a specific company profile."""
        company_id = request.data.get('id')
        if not company_id:
            return Response({"error": "Company ID required"}, status=status.HTTP_400_BAD_REQUEST)
            
        company = get_object_or_404(CompanyProfile, id=company_id, user=request.user)
        serializer = CompanyProfileSerializer(company, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request):
        """Delete a specific company profile."""
        company_id = request.data.get('id')
        if not company_id:
            return Response({"error": "Company ID required"}, status=status.HTTP_400_BAD_REQUEST)
            
        company = get_object_or_404(CompanyProfile, id=company_id, user=request.user)
        company.delete()
        return Response({"message": "Company deleted"}, status=status.HTTP_200_OK)

class JobApplicationViewSet(viewsets.ModelViewSet):
    queryset = JobApplication.objects.all()
    serializer_class = JobApplicationSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'admin':
            return JobApplication.objects.all()
        elif user.user_type == 'recruiter':
            company = CompanyProfile.objects.filter(user=user).first()
            return JobApplication.objects.filter(job__company=company)
        elif user.user_type == 'applicant':
            applicant = ApplicantProfile.objects.filter(user=user).first()
            return JobApplication.objects.filter(applicant=applicant)
        return JobApplication.objects.none()

    def perform_create(self, serializer):
        print(f"DEBUG: JobApplication create data: {self.request.data}")
        applicant = ApplicantProfile.objects.filter(user=self.request.user).first()
        if not applicant:
            raise ValidationError("You must have an Applicant Profile to apply for a job.")
        
        # Check if already applied
        job_id = self.request.data.get('job')
        if JobApplication.objects.filter(applicant=applicant, job_id=job_id).exists():
            raise ValidationError("You have already applied for this job.")
            
        serializer.save(applicant=applicant)

    def perform_update(self, serializer):
        # Only recruiters and admins can change status
        user = self.request.user
        if user.user_type not in ['recruiter', 'admin']:
            raise PermissionDenied("Only recruiters or administrators can update application status.")
        serializer.save()
