
from django.contrib import admin

from django.utils.html import format_html
from moderator.models import CompanyProfile

@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = [
        'company_name', 'user', 'owner_name', 'contact_number', 'website'
    ]
    search_fields = ['company_name', 'owner_name', 'user__username']
    list_filter = ['user']
    readonly_fields = ['logo_preview']
    fields = [
        'user', 'company_name', 'head_office_address', 'contact_number',
        'owner_name', 'owner_contact',
        'partner_name', 'partner_contact',
        'supervisor_name', 'supervisor_contact',
        'website', 'logo', 'logo_preview'
    ]

    def logo_preview(self, obj):
        if obj.logo:
            return format_html('<img src="{}" style="max-height:100px;"/>', obj.logo.url)
        return "No logo uploaded"
    logo_preview.short_description = "Logo Preview"

