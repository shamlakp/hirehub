from django.urls import path
from . import views

app_name = 'moderator'

urlpatterns = [
    path('', views.homepage, name='homepage'),
    path('jobs/', views.public_job_list, name='public_jobs'),
    path('register/', views.company_register, name='company_register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.company_dashboard, name='company_dashboard'),
    path('company/create/', views.create_company, name='create_company'),
    path('job/create/', views.create_job, name='create_job'), 
 
     ]

    

