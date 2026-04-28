import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const JoinInApp());
}

class JoinInApp extends StatelessWidget {
  const JoinInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JoinIn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // We only have a dark theme now as requested
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}
