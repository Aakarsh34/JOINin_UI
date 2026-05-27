import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/google_sign_in_service.dart';
import '../../state/auth_state.dart';
import '../../theme.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _googleBusy = false;

  Future<void> _continueWithGoogle() async {
    if (!GoogleSignInService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: const Text(
          'Google sign-in is not configured yet. Run `flutterfire configure` to enable it.',
          style: TextStyle(color: Colors.black),
        ),
      ));
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _googleBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthState>();
    try {
      final idToken = await GoogleSignInService.instance.signInAndGetIdToken();
      if (idToken == null) {
        if (!mounted) return;
        setState(() => _googleBusy = false);
        return;
      }
      await auth.loginWithGoogle(idToken: idToken);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(auth.error ?? 'Google sign-in failed'),
      ));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Icon(Icons.sports_baseball,
                      size: 56, color: AppTheme.darkBackground),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to JoinIn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find local sports sessions, host your own,\nand connect with players nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.cs.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: Icon(Icons.account_circle_outlined,
                    color: context.cs.onSurface),
                label: _googleBusy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: context.cs.onSurface,
                        ),
                      )
                    : Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: context.cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                onPressed: _googleBusy ? null : _continueWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(color: context.cs.outline),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone_iphone,
                    color: AppTheme.darkBackground),
                label: const Text('Continue with Mobile Number'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56)),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PhoneLoginScreen()));
                },
              ),
              const SizedBox(height: 24),
              Text(
                "By continuing you agree to JoinIn's terms\nand acknowledge our privacy policy.",
                style: TextStyle(
                    color: context.cs.onSurfaceVariant, fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
