from django.contrib import admin
from django.utils.html import format_html
from .models import CustomUser, PlatformSettings
from moderator.models import CompanyProfile

@admin.register(PlatformSettings)
class PlatformSettingsAdmin(admin.ModelAdmin):
    list_display = ('phone_number', 'whatsapp_number', 'email', 'whatsapp_link')
    fields = ('phone_number', 'whatsapp_number', 'email', 'address', 'whatsapp_link')
    
    def has_add_permission(self, request):
        # Only allow one instance of settings
        if self.model.objects.count() >= 1:
            return False
        return super().has_add_permission(request)

@admin.register(CustomUser)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'user_type', 'is_active')
    list_filter = ('user_type', 'is_active')
    search_fields = ('username', 'email')


@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = [
        'company_name', 'user', 'recruiter_name', 'contact_number', 'website'
    ]
    search_fields = ['company_name', 'recruiter_name', 'user__username']
    list_filter = ['user',]
    readonly_fields = ['logo_preview',]
    fields = [
        'user', 'company_name', 'head_office_address', 'contact_number',
        'recruiter_name', 'recruiter_contact',
        'partner_name', 'partner_contact',
        'supervisor_name', 'supervisor_contact',
        'website', 'logo', 'logo_preview'
    ]

    def logo_preview(self, obj):
        if obj.logo:
            return format_html('<img src="{}" style="max-height:100px;"/>', obj.logo.url)
        return "No logo uploaded"
    logo_preview.short_description = "Logo Preview"

