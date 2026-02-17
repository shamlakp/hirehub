from rest_framework import serializers
from .models import CompanyProfile, JobPost

class CompanyProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProfile
        fields = '__all__'

class JobPostSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source='company.company_name', read_only=True)
    
    class Meta:
        model = JobPost
        fields = ['id', 'position', 'company_name', 'no_of_vacancies', 'location', 'salary', 'is_approved', 'image', 'created_at', 'working_time', 'working_days', 'responsibilities', 'qualifications', 'benefits', 'annual_leave', 'industry', 'accommodation', 'meals', 'category']


class ApplicantProfileSerializer(serializers.ModelSerializer):
    resume = serializers.FileField(required=False, allow_null=True)

    class Meta:
        model = None
        fields = ['user', 'phone', 'resume', 'bio', 'skills']
        read_only_fields = ['user']

    def __init__(self, *args, **kwargs):
        # set the actual model dynamically to avoid circular imports
        from .models import ApplicantProfile as AP
        self.Meta.model = AP
        super().__init__(*args, **kwargs)

    def update(self, instance, validated_data):
        resume = validated_data.pop('resume', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if resume is not None:
            instance.resume = resume
        instance.save()
        return instance

    def create(self, validated_data):
        return self.Meta.model.objects.create(**validated_data)
