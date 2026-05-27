import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.cs.surfaceContainerLow,
              context.cs.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color:
                            AppTheme.primaryAccent.withValues(alpha: 0.22),
                        blurRadius: 40,
                        spreadRadius: 10)
                  ],
                ),
                child: const CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=Raj+K&background=00B4D8&color=fff'),
                ),
              ),
              const SizedBox(height: 32),
              Text('Raj Krishnamurthy',
                  style: TextStyle(
                      color: context.cs.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('02:45',
                  style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    active: _isMuted,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: AppTheme.danger,
                    iconColor: Colors.white,
                    size: 72,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _buildCallButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    active: _isSpeaker,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isSpeaker = !_isSpeaker);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    Color? color,
    Color? iconColor,
    bool active = false,
    required VoidCallback onTap,
    double size = 60,
  }) {
    final resolvedColor = color ??
        (active ? context.cs.onSurface : context.cs.surfaceContainerHigh);
    final resolvedIconColor = iconColor ??
        (active ? context.cs.surface : context.cs.onSurface);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: resolvedColor, shape: BoxShape.circle),
        child: Icon(icon, color: resolvedIconColor, size: size * 0.45),
      ),
    );
  }
}
