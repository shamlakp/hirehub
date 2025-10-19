from django.shortcuts import render,redirect,reverse
from .utils import get_dashboard_url
from .models import JobPost,CompanyProfile
from .forms import RecruiterForm,CompanyProfileForm,JobPostForm
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
    jobs = JobPost.objects.filter(is_approved=True)
    return render(request, 'moderator/public_jobs.html', {'jobs': jobs})


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

            # 🔹 Generate verification link
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            verification_link = f"{settings.DOMAIN}/verify/{uid}/{token}/"
            # 🔹 Send verification email
            send_mail(
                subject='Verify your HireHub account',
                message=f'Hi {user.username}, click the link to verify your account:\n{verification_link}',
                from_email='shamlawrk.347@gmail.com',
                recipient_list=[user.email],
                fail_silently=False,
            )

            return redirect('moderator:company_dashboard')  # or show a "check your email" page
    else:
        form = RecruiterForm()
    return render(request, 'moderator/company_register.html', {'form': form})



def get_dashboard_url(user):
    if not user:
        raise ValueError("User object is missing")

    user_type = getattr(user, 'user_type', None)

    if not user_type:
        raise ValueError("User type is missing or undefined")

    if user_type == 'admin':
        return reverse('adminpanel:admin_dashboard')
    elif user_type == 'owner':
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
        login(request, user)
        return redirect('moderator:company_dashboard')
    else:
        return HttpResponse('Verification link is invalid or expired.')


@login_required
def create_company(request):
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




    
