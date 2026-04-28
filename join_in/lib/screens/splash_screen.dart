import 'package:flutter/material.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_baseball, size: 120, color: AppTheme.darkBackground),
              const SizedBox(height: 24),
              Text(
                'JoinIn',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.darkBackground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find Your People. Build Your Community.',
                style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
