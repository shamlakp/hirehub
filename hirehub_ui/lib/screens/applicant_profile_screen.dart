import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ApplicantProfileScreen extends StatefulWidget {
  const ApplicantProfileScreen({super.key});

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  String? _resumePath;

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _resumePath = result.files.first.path;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'phone': _phone.text,
      'bio': _bio.text,
      'skills': _skills.text,
    };
    final success = await context.read<AuthProvider>().updateApplicantProfile(
      data,
      _resumePath,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().errorMessage ?? 'Failed',
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await context.read<AuthProvider>().fetchApplicantProfile();
    if (profile != null) {
      _phone.text = profile['phone'] ?? '';
      _bio.text = profile['bio'] ?? '';
      _skills.text = profile['skills'] ?? '';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicant Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bio,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skills,
                  decoration: const InputDecoration(labelText: 'Skills'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickResume,
                      child: const Text('Upload Resume'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_resumePath ?? 'No file selected')),
                  ],
                ),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return auth.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _save,
                            child: const Text('Save'),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
