import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../state/auth_state.dart';
import '../../theme.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    _countryCode = Env.defaultCountryCode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _fullPhone => '$_countryCode${_phoneController.text.trim()}';

  bool get _isValid {
    final digits = _phoneController.text.trim();
    return RegExp(r'^[1-9]\d{9,14}$').hasMatch(digits);
  }

  Future<void> _continue() async {
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    try {
      await auth.loginWithPhone(
        phone: _fullPhone,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(auth.error ?? 'Login failed'),
      ));
    }
  }

  Future<void> _pickCountryCode() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        const entries = [
          ('India', '+91'),
          ('United States', '+1'),
          ('United Kingdom', '+44'),
          ('UAE', '+971'),
          ('Canada', '+1'),
          ('Australia', '+61'),
          ('Singapore', '+65'),
          ('Germany', '+49'),
        ];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: entries
                .map((e) => ListTile(
                      title: Text(e.$1),
                      trailing: Text(e.$2,
                          style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.pop(ctx, e.$2),
                    ))
                .toList(),
          ),
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _countryCode = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Sign in', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            28,
            12,
            28,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in with your phone',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your mobile number to continue. We'll create your account if you don't already have one.",
                style: TextStyle(
                    color: context.cs.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              Text('Phone number',
                  style: TextStyle(
                      color: context.cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cs.outline),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _pickCountryCode,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        child: Row(
                          children: [
                            Text(_countryCode,
                                style: TextStyle(
                                    color: context.cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more,
                                color: context.cs.onSurfaceVariant, size: 18),
                          ],
                        ),
                      ),
                    ),
                    Container(
                        width: 1, height: 28, color: context.cs.outline),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                            fontSize: 18,
                            color: context.cs.onSurface,
                            letterSpacing: 1),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintText: '9876543210',
                          hintStyle:
                              TextStyle(color: context.cs.onSurfaceVariant),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Your name (optional)',
                  style: TextStyle(
                      color: context.cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: 16, color: context.cs.onSurface),
                decoration: const InputDecoration(
                  hintText: 'How should we call you?',
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: (_isValid && !auth.isBusy) ? _continue : null,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppTheme.darkBackground, strokeWidth: 3))
                    : const Text('Continue'),
              ),
              const SizedBox(height: 24),
              Text(
                'Existing users keep their saved name. New users will be created automatically.',
                style: TextStyle(
                    color: context.cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5),
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
