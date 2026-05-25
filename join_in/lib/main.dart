import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/auth_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App is forced into dark mode; make the Android status & nav bars match the
  // background instead of defaulting to the system light theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0D1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Env.load();
  await _initializeFirebaseSafely();
  runApp(const JoinInApp());
}

Future<void> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase isn't set up for this platform yet (no GoogleService-Info.plist
    // / google-services.json). The Google sign-in button hides itself when
    // Firebase isn't configured, so we let the rest of the app keep working.
    if (kDebugMode) {
      debugPrint('Firebase init skipped: $e');
    }
  }
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
          '/login': (context) => const LoginScreen(),
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
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const MainNavigation();
    }
  }
}
