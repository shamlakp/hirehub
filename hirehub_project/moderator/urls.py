from django.urls import path
from . import views
from rest_framework.routers import DefaultRouter

app_name = 'moderator'

urlpatterns = [
    path('', views.homepage, name='homepage'),
    path('jobs/', views.public_job_list, name='public_jobs'),
    path('register/', views.company_register, name='company_register'),
    path('applicant/register/', views.applicant_register, name='applicant_register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.company_dashboard, name='company_dashboard'),
    path('company/create/', views.create_company, name='create_company'),
    path('job/create/', views.create_job, name='create_job'),
    path('job/edit/<int:job_id>/', views.edit_job, name='edit_job'),
    path('job/delete/<int:job_id>/', views.delete_job, name='delete_job'), 
    path('verify/<uidb64>/<token>/', views.verify_email, name='verify_email'),
    path('job/<int:job_id>/', views.job_detail, name='job_detail'),
]

router = DefaultRouter()
router.register(r'api/companies', views.CompanyViewSet)
router.register(r'api/jobs', views.JobPostViewSet)

urlpatterns += router.urls

# Applicant API
urlpatterns += [
    path('api/applicant/register/', views.ApplicantRegisterAPI.as_view(), name='api_applicant_register'),
    path('api/applicant/profile/', views.ApplicantProfileAPI.as_view(), name='api_applicant_profile'),
    path('api/recruiter/profile/', views.RecruiterProfileAPI.as_view(), name='api_recruiter_profile'),
    path('api/logout/', views.LogoutAPI.as_view(), name='api_logout'),
]
