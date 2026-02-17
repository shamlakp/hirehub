
import 'package:flutter/material.dart';
import 'package:hirehub_ui/models/job_post.dart';
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

  // TODO: Add Resume Upload logic

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  void _submitApplication() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement API call to submit application
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
      Navigator.pop(context); // Go back to details
      Navigator.pop(context); // Go back to dashboard (optional, maybe stay on details)
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
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File picker not implemented yet')),
                          );
                      },
                      child: const Text('Browse Files'),
                    ),
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
                  child: const Text('Submit Application'),
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
    if (imagePath.startsWith('http')) return imagePath;
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '${UrlHelper.getBaseUrl()}$path';
  }
}
