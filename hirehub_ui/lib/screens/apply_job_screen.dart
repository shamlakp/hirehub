
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hirehub_ui/models/job_post.dart';
import 'package:hirehub_ui/services/api_service.dart';
import 'package:hirehub_ui/utils/url_helper.dart';

class ApplyJobScreen extends StatefulWidget {
  final JobPost job;
  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  PlatformFile? _resumeFile;
  bool _isLoading = false;

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _resumeFile = result.files.first;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  // Removed _isLoading since it's now at the top of State

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        await apiService.applyForJob(
          widget.job.id,
          notes: _coverLetterController.text,
          resumeFile: _resumeFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application submitted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Failed to submit application.';
          if (e is DioException && e.response?.data != null) {
            final data = e.response!.data;
            if (data is List && data.isNotEmpty) {
              errorMessage = data[0].toString();
            } else if (data is Map && data.containsKey('non_field_errors')) {
               errorMessage = data['non_field_errors'][0].toString();
            } else if (data is Map) {
               errorMessage = data.values.first.toString();
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apply for Job', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87, onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                     Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (widget.job.image != null && widget.job.image!.isNotEmpty)
                            ? Image.network(
                                _getImageUrl(widget.job.image!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.business, size: 24, color: Colors.grey),
                              )
                            : const Icon(Icons.business, size: 24, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.position,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(widget.job.companyName, style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.contains('@') ? null : 'Please enter a valid email',
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
              ),

              const SizedBox(height: 32),
              const Text(
                'Additional Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Resume Upload Placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Upload your Resume/CV'),
                    const SizedBox(height: 4),
                    Text(
                      'Supported formats: PDF, DOCX',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _pickResume,
                      child: Text(_resumeFile == null ? 'Browse Files' : 'Change File'),
                    ),
                    if (_resumeFile != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _resumeFile!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _coverLetterController,
                decoration: _inputDecoration('Cover Letter (Optional)').copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String _getImageUrl(String imagePath) {
    return UrlHelper.resolveMediaUrl(imagePath);
  }
}
