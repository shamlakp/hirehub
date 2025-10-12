from django.shortcuts import render,redirect
from .utils import get_dashboard_url
from .models import JobPost,CompanyProfile
from .forms import RecruiterForm,CompanyProfileForm,JobPostForm
from django.contrib.auth import authenticate,login,logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.mail import send_mail


def homepage(request):
    jobs = JobPost.objects.filter(is_approved=True)
    return render(request, 'homepage.html', {'jobs': jobs})


@login_required
def recruiter_dashboard(request):
    company = CompanyProfile.objects.filter(user=request.user).first()
    jobs = JobPost.objects.filter(company=company).order_by('-id') if company else []
    return render(request, 'moderator/recruiter_dashboard.html', {
        'company': company,
        'jobs': jobs
    })    

def public_job_list(request):
    jobs = JobPost.objects.filter(is_approved=True)
    return render(request, 'moderator/public_jobs.html', {'jobs': jobs})

def recruiter_register(request):
    if request.method == 'POST':
        form = RecruiterForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user) 
            send_mail(
                subject='Welcome to HireHub!',
                message=f'Hi {user.username}, your company account has been created successfully.',
                from_email='shamlawrk.347@gmail.com',
                recipient_list=[user.email],
                fail_silently=False,
            )
            return redirect('moderator:recruiter_dashboard')
    else:
        form = RecruiterForm()
    return render(request, 'moderator/recruiter_register.html', {'form': form})


def login_view(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user:
            login(request, user)
            return redirect(get_dashboard_url(user))
    return render(request, 'moderator/login.html')       


def logout_view(request):
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect('moderator:homepage')  

@login_required
def create_company(request):
    if CompanyProfile.objects.filter(user=request.user).exists():
        return redirect('moderator:recruiter_dashboard')

    if request.method == 'POST':
        form = CompanyProfileForm(request.POST, request.FILES)  # ✅ Include request.FILES
        if form.is_valid():
            company = form.save(commit=False)
            company.user = request.user
            company.save()
            return redirect('moderator:recruiter_dashboard')
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
            return redirect('moderator:recruiter_dashboard')
    return render(request, 'moderator/create_job.html', {'form': form})