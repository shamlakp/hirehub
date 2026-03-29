import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _otpSent = false;
  bool _otpVerified = false;
  final _otpController = TextEditingController();

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    
    if (!_otpSent) {
      final success = await auth.sendOTP(email);
      if (success && mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Failed to send OTP')),
        );
      }
      return;
    }
    
    if (!_otpVerified) {
      final otp = _otpController.text.trim();
      final success = await auth.verifyOTP(email, otp);
      if (success && mounted) {
        setState(() => _otpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! Please set a password.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Invalid OTP')),
        );
      }
      return;
    }
    
    // Final registration
    final data = {
      'username': _username.text.trim(),
      'email': email,
      'password': _password.text.trim(),
    };
    final success = await auth.registerRecruiter(data);
    if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. You can log in immediately.'),
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
    } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Registration failed')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recruiter Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                enabled: !_otpVerified,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_otpSent,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              if (_otpSent && !_otpVerified) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'Enter 6-digit OTP'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
              if (_otpVerified) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                ),
              ],
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleAction,
                          child: Text(!_otpSent 
                              ? 'Send OTP' 
                              : (!_otpVerified ? 'Verify OTP' : 'Register')),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
