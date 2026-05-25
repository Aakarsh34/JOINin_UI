import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text(
          'Google sign-in is not configured yet. Run `flutterfire configure` to enable it.',
          style: TextStyle(color: Colors.black),
        ),
      ));
      return;
    }
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
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(Icons.sports_baseball, size: 56, color: AppTheme.darkBackground),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to JoinIn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Find local sports sessions, host your own, and connect with players nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.account_circle_outlined, color: AppTheme.textLight),
                label: _googleBusy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.textLight))
                    : const Text('Continue with Google', style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: _googleBusy ? null : _continueWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone_iphone, color: AppTheme.darkBackground),
                label: const Text('Continue with Mobile Number'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'By continuing you agree to JoinIn\'s terms and acknowledge our privacy policy.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
