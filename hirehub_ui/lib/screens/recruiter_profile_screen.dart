
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/url_helper.dart';

class RecruiterProfileScreen extends StatefulWidget {
  const RecruiterProfileScreen({super.key});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _recruiterNameController = TextEditingController();
  final _recruiterContactController = TextEditingController();
  
  PlatformFile? _pickedFile;
  String? _existingLogoUrl;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _recruiterNameController.dispose();
    _recruiterContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await context.read<AuthProvider>().fetchRecruiterProfile();
    if (mounted) {
      if (profile != null) {
        _companyNameController.text = profile['company_name'] ?? '';
        _websiteController.text = profile['website'] ?? '';
        _addressController.text = profile['head_office_address'] ?? '';
        _recruiterNameController.text = profile['recruiter_name'] ?? '';
        _recruiterContactController.text = profile['recruiter_contact'] ?? '';
        _existingLogoUrl = profile['logo'];
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true); // Force load bytes for web
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final data = {
      'company_name': _companyNameController.text,
      'website': _websiteController.text,
      'head_office_address': _addressController.text,
      'recruiter_name': _recruiterNameController.text,
      'recruiter_contact': _recruiterContactController.text,
    };

    final success = await context.read<AuthProvider>().updateRecruiterProfile(
      data,
      _pickedFile,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AuthProvider>().errorMessage ?? 'Failed to save profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('Company Profile', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _pickedFile != null
                                ? (kIsWeb && _pickedFile!.bytes != null 
                                    ? Image.memory(_pickedFile!.bytes!, fit: BoxFit.cover) 
                                    : (_pickedFile!.path != null ? Image.asset('assets/images/placeholder.png') : Icon(Icons.check, color: Colors.green))) // Fallback for file path if not web and bytes missing
                                : (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty)
                                    ? Image.network(
                                        _getImageUrl(_existingLogoUrl!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.business, size: 40, color: Colors.grey),
                                      )
                                    : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(child: Text('Tap to change logo', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Company Information'),
                    _buildField(controller: _companyNameController, label: 'Company Name', icon: Icons.business),
                    const SizedBox(height: 16),
                    _buildField(controller: _websiteController, label: 'Website', icon: Icons.language),
                    const SizedBox(height: 16),
                    _buildField(controller: _addressController, label: 'Head Office Address', icon: Icons.location_on, maxLines: 2),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Recruiter Details'),
                    _buildField(controller: _recruiterNameController, label: 'Recruiter Name', icon: Icons.person),
                    const SizedBox(height: 16),
                    _buildField(controller: _recruiterContactController, label: 'Contact Number', icon: Icons.phone),

                    const SizedBox(height: 40),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF673AB7), // Matching theme
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
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
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF673AB7)),
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
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
    );
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '${UrlHelper.getBaseUrl()}$path';
  }
}
