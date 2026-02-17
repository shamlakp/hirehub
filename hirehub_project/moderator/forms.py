from django import forms
from .models import CompanyProfile, JobPost
from adminpanel.models import CustomUser
from django import forms
from django.core.validators import validate_email
from django.core.exceptions import ValidationError
from adminpanel.models import CustomUser

class RecruiterForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={'placeholder': 'Enter password'}),
        required=True
    )
    confirm_password = forms.CharField(
        widget=forms.PasswordInput(attrs={'placeholder': 'Confirm password'}),
        required=True,
        label="Confirm Password"
    )

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password']
        help_texts = {
            'username': '',
        }

    def clean_email(self):
        email = self.cleaned_data.get('email')
        try:
            validate_email(email)
        except ValidationError:
            raise forms.ValidationError("Enter a valid email address.")
        return email

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password and confirm_password and password != confirm_password:
            self.add_error('confirm_password', "Passwords do not match")

    def save(self, commit=True):
        user = super().save(commit=False)
        user.user_type = 'recruiter'  # Set to recruiter for company accounts
        if self.cleaned_data['password']:
            user.set_password(self.cleaned_data['password'])
        if commit:
            user.save()
        return user


class ApplicantForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={'placeholder': 'Enter password'}),
        required=True
    )
    confirm_password = forms.CharField(
        widget=forms.PasswordInput(attrs={'placeholder': 'Confirm password'}),
        required=True,
        label="Confirm Password"
    )

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password']

    def clean_email(self):
        email = self.cleaned_data.get('email')
        try:
            validate_email(email)
        except ValidationError:
            raise forms.ValidationError("Enter a valid email address.")
        return email

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password and confirm_password and password != confirm_password:
            self.add_error('confirm_password', "Passwords do not match")

    def save(self, commit=True):
        user = super().save(commit=False)
        user.user_type = 'applicant'
        user.is_active = False # Set to False for email verification
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
             'user','company_name',  'recruiter_contact','website', 'logo',
             'head_office_address',
             'partner_name', 'partner_contact',
            'supervisor_name', 'supervisor_contact' 
        ]
        labels = {
            'recruiter_name': 'Recruiter Name',
            'recruiter_contact': 'Recruiter Contact',
        }
        widgets = {
            'company_name': forms.TextInput(attrs={'class': 'form-control'}),
            'recruiter_name': forms.TextInput(attrs={'class': 'form-control'}),
            'recruiter_contact': forms.TextInput(attrs={'class': 'form-control'}),
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
            'position','no_of_vacancies','location','responsibilities', 'qualifications',
            'working_days', 'working_time', 'salary',
            'annual_leave', 'benefits', 
        ]
        widgets ={
            'position': forms.TextInput(attrs={'class': 'form-control'}),
            'no_of_vacancies ': forms.NumberInput(attrs={'class': 'form-control'}),
            'location': forms.TextInput(attrs={'class': 'form-control'}),
            'responsibilities': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'qualifications': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'working_days': forms.TextInput(attrs={'class': 'form-control'}),
            'working_time': forms.TextInput(attrs={'class': 'form-control'}),
            'salary': forms.TextInput(attrs={'class': 'form-control'}),
            'annual_leave': forms.NumberInput(attrs={'class': 'form-control'}),
            'benefits': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
        }

 