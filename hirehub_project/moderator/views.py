from django.shortcuts import render,redirect,reverse, get_object_or_404
from django.http import HttpResponse # Added
from .utils import get_dashboard_url
from .models import JobPost, CompanyProfile, ApplicantProfile # Added ApplicantProfile
from .forms import RecruiterForm, ApplicantForm, CompanyProfileForm, JobPostForm
from django.contrib.auth import authenticate,login,logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.conf import settings
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_decode
from django.contrib.auth import get_user_model


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

            # 🔹 Create inactive user
            user = form.save(commit=False)
            user.is_active = False
            user.save()

            # 🔹 Send verification email using utility
            from .utils import send_verification_email
            send_verification_email(user)

            return redirect('moderator:company_dashboard')  # or show a "check your email" page
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
            from .utils import send_verification_email
            send_verification_email(user)
            messages.success(request, "Registration successful. Please check your email to verify your account.")
            return redirect('moderator:login')
    else:
        form = ApplicantForm()
    return render(request, 'moderator/applicant_register.html', {'form': form})



def get_dashboard_url(user):
    if not user:
        raise ValueError("User object is missing")

    user_type = getattr(user, 'user_type', None)

    if not user_type:
        raise ValueError("User type is missing or undefined")

    if user_type == 'admin':
        return reverse('adminpanel:admin_dashboard')
    elif user_type == 'recruiter':
        return reverse('moderator:company_dashboard')
    else:
        raise ValueError(f"Unknown user type: {user_type}")


def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user :
            login(request, user)
            from .utils import notify_admin_on_login
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
    # Only users with type 'recruiter' can create a company profile
    if request.user.user_type != 'recruiter':
        return redirect('moderator:company_dashboard')

    if CompanyProfile.objects.filter(user=request.user).exists():
        return redirect('moderator:company_dashboard')

    if request.method == 'POST':
        form = CompanyProfileForm(request.POST, request.FILES)  # ✅ Include request.FILES
        if form.is_valid():
            company = form.save(commit=False)
            company.user = request.user
            company.save()
            return redirect('moderator:company_dashboard')
    else:
        form = CompanyProfileForm()

    return render(request, 'moderator/create_company.html', {'form': form})



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


from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import CompanyProfileSerializer, JobPostSerializer
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


from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .serializers import CompanyProfileSerializer, JobPostSerializer
from adminpanel.serializers import ApplicantSerializer

class CompanyViewSet(viewsets.ModelViewSet):
    queryset = CompanyProfile.objects.all()
    serializer_class = CompanyProfileSerializer
    parser_classes = [MultiPartParser, FormParser]

class JobPostViewSet(viewsets.ModelViewSet):
    queryset = JobPost.objects.all().order_by('-created_at')
    serializer_class = JobPostSerializer
    authentication_classes = [TokenAuthentication]
    parser_classes = [MultiPartParser, FormParser]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated()]
        return []

    def perform_create(self, serializer):
        # Automatically assign the recruiter's company to the job post
        company = CompanyProfile.objects.filter(user=self.request.user).first()
        if not company:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("You must create a Company Profile before posting a job.")
        serializer.save(company=company)


class ApplicantRegisterAPI(APIView):
    def post(self, request):
        from adminpanel.serializers import ApplicantSerializer
        serializer = ApplicantSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = False
            user.save()
            from .utils import send_verification_email
            send_verification_email(user)
            return Response({"message": "Registration successful. Please verify your email."}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LogoutAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # Clear Django session if exists (important for web)
            from django.contrib.auth import logout as django_logout
            django_logout(request)
            
            # Delete DRF token
            if hasattr(request.user, 'auth_token'):
                request.user.auth_token.delete()
                
            return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class ApplicantProfileAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):
        profile, _ = ApplicantProfile.objects.get_or_create(user=request.user)
        from .serializers import ApplicantProfileSerializer
        serializer = ApplicantProfileSerializer(profile)
        return Response(serializer.data)

    def patch(self, request):
        profile, _ = ApplicantProfile.objects.get_or_create(user=request.user)
        from .serializers import ApplicantProfileSerializer
        serializer = ApplicantProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)





    
class RecruiterProfileAPI(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):
        company, _ = CompanyProfile.objects.get_or_create(user=request.user)
        # Handle case where company name might not be set initially
        if not company.company_name:
             company.company_name = f"{request.user.username} Company"
             company.save()
             
        from .serializers import CompanyProfileSerializer
        serializer = CompanyProfileSerializer(company)
        return Response(serializer.data)

    def patch(self, request):
        company, _ = CompanyProfile.objects.get_or_create(user=request.user)
        from .serializers import CompanyProfileSerializer
        serializer = CompanyProfileSerializer(company, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
