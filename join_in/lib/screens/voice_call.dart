import 'package:flutter/material.dart';
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
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF161B22), AppTheme.darkBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Call Info
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                ),
                child: const CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Raj+K&background=00B4D8&color=fff'),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Raj Krishnamurthy', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('02:45', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 2)),
              
              const Spacer(),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.white : Colors.white10,
                    iconColor: _isMuted ? AppTheme.darkBackground : Colors.white,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: Colors.redAccent,
                    iconColor: Colors.white,
                    size: 72,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildCallButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    color: _isSpeaker ? Colors.white : Colors.white10,
                    iconColor: _isSpeaker ? AppTheme.darkBackground : Colors.white,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
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
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}
