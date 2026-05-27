import 'dart:async';

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
import 'state/theme_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Env must be ready before the first API call, but it only reads a small
  // bundled asset (~10 ms) so it's still cheap to await up front.
  await Env.load();
  // Firebase init can race with the first frame: even if it ends up failing
  // (e.g. no GoogleService-Info.plist in dev builds) we don't want it to add
  // ~200-400 ms before runApp.
  unawaited(_initializeFirebaseSafely());
  runApp(const JoinInApp());
}

Future<void> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init skipped: $e');
    }
  }
}

class JoinInApp extends StatelessWidget {
  const JoinInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AuthState()..bootstrap()),
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, _) {
          return MaterialApp(
            title: 'JoinIn',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.mode,
            themeAnimationDuration: const Duration(milliseconds: 200),
            themeAnimationCurve: Curves.easeInOutCubic,
            home: const _SystemChromeBinding(child: _AuthGate()),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/main': (context) => const MainNavigation(),
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Keeps the Android status bar + nav bar in sync with whichever theme is
/// currently active. Sits just under [MaterialApp] so [Theme.of] is available.
class _SystemChromeBinding extends StatelessWidget {
  const _SystemChromeBinding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return child;
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(auth.status),
        child: switch (auth.status) {
          AuthStatus.unknown => const SplashScreen(),
          AuthStatus.signedOut => const LoginScreen(),
          AuthStatus.signedIn => const MainNavigation(),
        },
      ),
    );
  }
}
