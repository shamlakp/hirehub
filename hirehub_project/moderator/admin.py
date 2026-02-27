from django.contrib import admin
from .models import ApplicantProfile, JobPost, JobApplication

class JobPostAdmin(admin.ModelAdmin):
    list_display = ('position', 'company', 'location', 'no_of_vacancies', 'is_approved')
    list_filter = ('is_approved', 'company')
    search_fields = ('position', 'company__company_name')

class JobApplicationAdmin(admin.ModelAdmin):
    list_display = ('job', 'applicant', 'status', 'applied_at')
    list_filter = ('status', 'applied_at')
    search_fields = ('job__position', 'applicant__user__username')
    actions = ['mark_shortlisted', 'mark_rejected', 'mark_pending']

    def mark_shortlisted(self, request, queryset):
        queryset.update(status='shortlisted')
    mark_shortlisted.short_description = "Mark selected as Shortlisted"

    def mark_rejected(self, request, queryset):
        queryset.update(status='rejected')
    mark_rejected.short_description = "Mark selected as Rejected"

    def mark_pending(self, request, queryset):
        queryset.update(status='pending')
    mark_pending.short_description = "Mark selected as Pending (Reset)"

admin.site.register(ApplicantProfile)
admin.site.register(JobPost, JobPostAdmin)
admin.site.register(JobApplication, JobApplicationAdmin)

