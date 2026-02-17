from django.urls import path
from . import views

app_name = 'adminpanel'

urlpatterns = [
    path('dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('approve-job/<int:job_id>/', views.approve_job, name='approve_job'),
    path('deactivate-job/<int:job_id>/', views.deactivate_job, name='deactivate_job'),
    #job/company management
     path('company/add/', views.add_company,    name='add_company'),
     path('jobs/', views.manage_jobs, name='manage_jobs'),
     path('companies/', views.manage_companies, name='manage_companies'),
     path('company/<int:company_id>/ajax-edit/', views.ajax_edit_company, name='ajax_edit_company'),
     path('company/<int:company_id>/ajax-delete/', views.ajax_delete_company, name='ajax_delete_company'),
     path('job/<int:job_id>/ajax-edit/', views.ajax_edit_job, name='ajax_edit_job'),
     path('job/<int:job_id>/ajax-delete/', views.ajax_delete_job, name='ajax_delete_job'),
     
     # APIs
     path('api/login/', views.LoginAPI.as_view(), name='api_login'),
     path('api/register/', views.RegisterAPI.as_view(), name='api_register'),
    path('api/platform-settings/', views.PlatformSettingsAPI.as_view(), name='api_platform_settings'),
]
