import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../state/auth_state.dart';
import '../../theme.dart';
import 'otp_verify_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    _countryCode = Env.defaultCountryCode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '$_countryCode${_phoneController.text.trim()}';

  bool get _isValid {
    final digits = _phoneController.text.trim();
    return RegExp(r'^[1-9]\d{9,14}$').hasMatch(digits);
  }

  Future<void> _sendOtp() async {
    if (!_isValid) return;
    final auth = context.read<AuthState>();
    FocusScope.of(context).unfocus();
    try {
      await auth.sendOtp(_fullPhone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpVerifyScreen(phone: _fullPhone),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(auth.error ?? 'Failed to send OTP'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.sports_baseball, size: 48, color: AppTheme.primaryAccent),
              const SizedBox(height: 32),
              Text(
                'Welcome to JoinIn',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in with your phone number to find and host local sports sessions.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 40),
              const Text('Phone number', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: AppTheme.cardDarkElevated,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (ctx) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: const [
                                ListTile(title: Text('India (+91)'), trailing: Text('+91')),
                                ListTile(title: Text('United States (+1)'), trailing: Text('+1')),
                                ListTile(title: Text('United Kingdom (+44)'), trailing: Text('+44')),
                                ListTile(title: Text('UAE (+971)'), trailing: Text('+971')),
                              ]
                                  .map((tile) => ListTile(
                                        title: tile.title,
                                        trailing: tile.trailing,
                                        onTap: () => Navigator.pop(ctx, (tile.trailing as Text).data),
                                      ))
                                  .toList(),
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _countryCode = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Row(
                          children: [
                            Text(_countryCode, style: const TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Icon(Icons.expand_more, color: AppTheme.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.white10),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 18, color: AppTheme.textLight, letterSpacing: 1),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '9876543210',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isValid && !auth.isBusy) ? _sendOtp : null,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 3),
                      )
                    : const Text('Send OTP'),
              ),
              const Spacer(),
              const Text(
                'By continuing you agree to receive an SMS code from JoinIn.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
