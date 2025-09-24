from django import forms
from .models import CompanyProfile, JobPost
from adminpanel.models import CustomUser

class RecruiterForm(forms.ModelForm):
    password = forms.CharField(widget=forms.PasswordInput, required=False)

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password']

    def save(self, commit=True):
        user = super().save(commit=False)
        user.user_type = 'recruiter'
        if self.cleaned_data['password']:
            user.set_password(self.cleaned_data['password'])
        if commit:
            user.save()
        return user




class CompanyProfileForm(forms.ModelForm):
    user = forms.ModelChoiceField(
        queryset=CustomUser.objects.filter(user_type='recruiter'),
        label="Recruiter",
        widget=forms.Select(attrs={'class': 'form-select'})
    )

    class Meta:
        model = CompanyProfile
        fields = [
            'user', 'company_name', 'owner_name', 'owner_contact','website', 'logo',
             'head_office_address',
             'partner_name', 'partner_contact',
            'supervisor_name', 'supervisor_contact' 
        ]
        widgets = {
            'company_name': forms.TextInput(attrs={'class': 'form-control'}),
            'owner_name': forms.TextInput(attrs={'class': 'form-control'}),
            'owner_contact': forms.TextInput(attrs={'class': 'form-control'}),
            'partner_name': forms.TextInput(attrs={'class': 'form-control'}),
            'partner_contact': forms.TextInput(attrs={'class': 'form-control'}),
            'supervisor_name': forms.TextInput(attrs={'class': 'form-control'}),
            'supervisor_contact': forms.TextInput(attrs={'class': 'form-control'}),
            'head_office_address': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
            'website': forms.URLInput(attrs={'class': 'form-control'}),
            'logo': forms.ClearableFileInput(attrs={'class': 'form-control'}),
        }

class JobPostForm(forms.ModelForm):
    class Meta:
        model = JobPost
        fields = [
            'title', 'responsibilities', 'qualifications',
            'working_days', 'working_time', 'salary',
            'annual_leave', 'benefits', 
        ]
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'responsibilities': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'qualifications': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'working_days': forms.TextInput(attrs={'class': 'form-control'}),
            'working_time': forms.TextInput(attrs={'class': 'form-control'}),
            'salary': forms.TextInput(attrs={'class': 'form-control'}),
            'annual_leave': forms.NumberInput(attrs={'class': 'form-control'}),
            'benefits': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
        }

 