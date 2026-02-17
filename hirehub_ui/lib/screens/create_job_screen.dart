
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../providers/job_provider.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Details
  final _positionController = TextEditingController();
  final _categoryController = TextEditingController(); // New
  final _industryController = TextEditingController(); // New
  
  // Requirements
  final _vacanciesController = TextEditingController();
  final _responsibilitiesController = TextEditingController(); // New
  final _qualificationsController = TextEditingController(); // New
  
  // Terms
  final _locationController = TextEditingController();
  final _workingTimeController = TextEditingController(text: 'Full Time'); // New
  final _workingDaysController = TextEditingController(text: 'Mon-Fri'); // New
  final _salaryController = TextEditingController();
  final _annualLeaveController = TextEditingController(text: '30'); // New
  
  // Perks
  final _accommodationController = TextEditingController(); // New (e.g. Provided by company)
  final _mealsController = TextEditingController(); // New (e.g. Not included)
  final _benefitsController = TextEditingController(); // New
  
  File? _selectedImage;
  String? _webImage; 
  bool _isSubmitting = false;

  @override
  void dispose() {
    _positionController.dispose();
    _categoryController.dispose();
    _industryController.dispose();
    _vacanciesController.dispose();
    _responsibilitiesController.dispose();
    _qualificationsController.dispose();
    _locationController.dispose();
    _workingTimeController.dispose();
    _workingDaysController.dispose();
    _salaryController.dispose();
    _annualLeaveController.dispose();
    _accommodationController.dispose();
    _mealsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile.path;
        } else {
          _selectedImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await context.read<JobProvider>().createJob(
      {
        'position': _positionController.text,
        'category': _categoryController.text,
        'industry': _industryController.text,
        'noOfVacancies': int.parse(_vacanciesController.text),
        'responsibilities': _responsibilitiesController.text,
        'qualifications': _qualificationsController.text,
        'location': _locationController.text,
        'workingTime': _workingTimeController.text,
        'workingDays': _workingDaysController.text,
        'salary': _salaryController.text,
        'annualLeave': int.tryParse(_annualLeaveController.text) ?? 0,
        'accommodation': _accommodationController.text,
        'meals': _mealsController.text,
        'benefits': _benefitsController.text,
      },
      imagePath: _selectedImage?.path,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully! Waiting for admin approval.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<JobProvider>().errorMessage ?? 'Failed to post job')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Job'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // Background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: (_selectedImage != null || _webImage != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(_webImage!, fit: BoxFit.cover)
                              : Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Add Job Photo', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Job Overview'),
              _buildField(controller: _positionController, label: 'Job Position', icon: Icons.work_outline),
              const SizedBox(height: 16),
              _buildField(controller: _categoryController, label: 'Category', hint: 'e.g. IT, Healthcare', icon: Icons.category_outlined),
              const SizedBox(height: 16),
              _buildField(controller: _industryController, label: 'Industry', hint: 'e.g. Software, Hospital', icon: Icons.business_outlined),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Requirements'),
              _buildField(controller: _vacanciesController, label: 'No. of Vacancies', icon: Icons.people_outline, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(controller: _qualificationsController, label: 'Qualifications', hint: 'e.g. Degree in CS', icon: Icons.school_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _buildField(controller: _responsibilitiesController, label: 'Responsibilities', hint: 'Key duties...', icon: Icons.description_outlined, maxLines: 3),

              const SizedBox(height: 24),
              _buildSectionTitle('Terms & Compensation'),
              Row(
                children: [
                  Expanded(child: _buildField(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(controller: _salaryController, label: 'Salary', icon: Icons.payments_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(controller: _workingTimeController, label: 'Working Time', icon: Icons.access_time)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(controller: _workingDaysController, label: 'Working Days', icon: Icons.calendar_today)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(controller: _annualLeaveController, label: 'Annual Leave (Days)', icon: Icons.flight_takeoff, keyboardType: TextInputType.number),

              const SizedBox(height: 24),
              _buildSectionTitle('Perks & Facilities'),
              _buildField(controller: _accommodationController, label: 'Accommodation', hint: 'e.g. Provided', icon: Icons.home_work_outlined),
              const SizedBox(height: 16),
              _buildField(controller: _mealsController, label: 'Meals', hint: 'e.g. Not included', icon: Icons.restaurant_outlined),
              const SizedBox(height: 16),
              _buildField(controller: _benefitsController, label: 'Other Benefits', hint: 'e.g. Insurance, Transport', icon: Icons.card_giftcard, maxLines: 2),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Post Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }
}
