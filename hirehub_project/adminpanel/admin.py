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
    actions = ['activate_users', 'deactivate_users']

    def activate_users(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} users were successfully activated.')
    activate_users.short_description = "Activate selected users"

    def deactivate_users(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} users were successfully deactivated.')
    deactivate_users.short_description = "Deactivate selected users"


@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = [
        'company_name', 'user', 'recruiter_name', 'contact_number', 'is_active_status', 'toggle_status'
    ]
    search_fields = ['company_name', 'recruiter_name', 'user__username']
    list_filter = ['user__is_active',]
    actions = ['activate_recruiters', 'deactivate_recruiters']
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
            return format_html('<img src="{}" style="max-height:200px;"/>', obj.logo.url)
        return "No logo uploaded"
    logo_preview.short_description = "Logo Preview"

    def is_active_status(self, obj):
        if obj.user.is_active:
            return format_html('<span style="color: green; font-weight: bold;">Active</span>')
        return format_html('<span style="color: red; font-weight: bold;">Inactive</span>')
    is_active_status.short_description = 'Status'

    def toggle_status(self, obj):
        if obj.user.is_active:
            return format_html(
                '<a class="button" href="deactivate/{}/" style="background-color: #ba2121; color: white; padding: 5px 10px; border-radius: 4px; text-decoration: none;">Deactivate</a>',
                obj.pk
            )
        return format_html(
            '<a class="button" href="activate/{}/" style="background-color: #417690; color: white; padding: 5px 10px; border-radius: 4px; text-decoration: none;">Activate</a>',
            obj.pk
        )
    toggle_status.short_description = 'Actions'

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('activate/<int:pk>/', self.activate_recruiter_view, name='activate_recruiter'),
            path('deactivate/<int:pk>/', self.deactivate_recruiter_view, name='deactivate_recruiter'),
        ]
        return custom_urls + urls

    def activate_recruiter_view(self, request, pk):
        profile = self.model.objects.get(pk=pk)
        profile.user.is_active = True
        profile.user.save()
        self.message_user(request, f"Recruiter {profile.company_name} activated.")
        from django.shortcuts import redirect
        return redirect('..')

    def deactivate_recruiter_view(self, request, pk):
        profile = self.model.objects.get(pk=pk)
        profile.user.is_active = False
        profile.user.save()
        self.message_user(request, f"Recruiter {profile.company_name} deactivated.")
        from django.shortcuts import redirect
        return redirect('..')

    def activate_recruiters(self, request, queryset):
        for profile in queryset:
            profile.user.is_active = True
            profile.user.save()
        self.message_user(request, f"{queryset.count()} recruiters activated.")
    activate_recruiters.short_description = "Activate selected recruiters"

    def deactivate_recruiters(self, request, queryset):
        for profile in queryset:
            profile.user.is_active = False
            profile.user.save()
        self.message_user(request, f"{queryset.count()} recruiters deactivated.")
    deactivate_recruiters.short_description = "Deactivate selected recruiters"

