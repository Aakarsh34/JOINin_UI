import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/auth_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  runApp(const JoinInApp());
}

class JoinInApp extends StatelessWidget {
  const JoinInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState()..bootstrap(),
      child: MaterialApp(
        title: 'JoinIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const _AuthGate(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/main': (context) => const MainNavigation(),
          '/login': (context) => const PhoneLoginScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.signedOut:
        return const PhoneLoginScreen();
      case AuthStatus.signedIn:
        return const MainNavigation();
    }
  }
}
