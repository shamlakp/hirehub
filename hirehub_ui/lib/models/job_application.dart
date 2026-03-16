class JobApplication {
  final int id;
  final int jobId;
  final String jobPosition;
  final String companyName;
  final String applicantName;
  final String status;
  final String appliedAt;
  final String notes;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobPosition,
    required this.companyName,
    required this.applicantName,
    required this.status,
    required this.appliedAt,
    this.notes = '',
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'],
      jobId: json['job'],
      jobPosition: json['job_position'] ?? 'Unknown Position',
      companyName: json['company_name'] ?? 'Unknown Company',
      applicantName: json['applicant_name'] ?? 'Unknown Applicant',
      status: json['status'] ?? 'pending',
      appliedAt: json['applied_at'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
