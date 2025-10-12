from django.urls import path
from . import views

app_name = 'moderator'

urlpatterns = [
    path('', views.homepage, name='homepage'),
    path('jobs/', views.public_job_list, name='public_jobs'),
    path('register/', views.recruiter_register, name='recruiter_register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.recruiter_dashboard, name='recruiter_dashboard'),
    path('company/create/', views.create_company, name='create_company'),
    path('job/create/', views.create_job, name='create_job'), 
    
     ]

    

