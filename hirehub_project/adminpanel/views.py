from django.shortcuts import render,redirect,get_object_or_404
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .decorators import admin_required 
from django.contrib.auth.decorators import login_required
from moderator.models import JobPost, CompanyProfile
from adminpanel.models import CustomUser
from .decorators import admin_required
from django.urls import reverse
from django.http import JsonResponse
from moderator.forms import JobPostForm, CompanyProfileForm
from moderator.models import CompanyProfile
import json

@login_required
@admin_required
def admin_dashboard(request):
    jobs = JobPost.objects.all().order_by('-id')
    recruiters = CustomUser.objects.filter(user_type='recruiter')
    return render(request, 'adminpanel/dashboard.html', {
        'jobs': jobs,
        'recruiters': recruiters
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
def ajax_delete_company(request, company_id):
    if request.method == 'POST' and request.user.user_type == 'admin':
        try:
            company = CompanyProfile.objects.get(id=company_id)
            company.delete()
            return JsonResponse({'success': True})
        except CompanyProfile.DoesNotExist:
            return JsonResponse({'success': False, 'error': 'Company not found'})
    return JsonResponse({'success': False, 'error': 'Invalid request'})



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


 