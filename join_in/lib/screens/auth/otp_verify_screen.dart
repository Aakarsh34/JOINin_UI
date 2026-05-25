import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  const OtpVerifyScreen({super.key, required this.phone});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthState>();
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;
    FocusScope.of(context).unfocus();
    try {
      await auth.verifyOtp(phone: widget.phone, otp: otp);
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(auth.error ?? 'Verification failed'),
      ));
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthState>();
    try {
      await auth.sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        content: Text('OTP re-sent', style: TextStyle(color: AppTheme.darkBackground)),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textLight),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify it\'s you',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code we sent to ${widget.phone}.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  hintText: '••••••',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, letterSpacing: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_otpController.text.length == 6 && !auth.isBusy) ? _verify : null,
                child: auth.isBusy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 3))
                    : const Text('Verify and continue'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: auth.isBusy ? null : _resend,
                  child: const Text('Didn\'t receive it? Resend', style: TextStyle(color: AppTheme.primaryAccent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
