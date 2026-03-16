import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/mezban_logo.dart';
import 'dashboard_screen.dart';

/// Splash screen that checks authentication status on app startup
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize authentication state
    await context.read<AuthProvider>().initializeAuth();

    if (mounted) {
      // Always navigate to DashboardScreen (Home) regardless of auth status
      // The Dashboard will handle guest/authenticated states
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MezbanLogo(fontSize: 40, showText: true),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
            ),
          ],
        ),
      ),
    );
  }
}
