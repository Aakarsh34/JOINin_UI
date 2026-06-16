import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/glass.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: 0.85 + (_scale.value * 0.15),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(32),
                  blur: 16,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 32),
                  tint: Colors.white.withValues(alpha: 0.15),
                  borderColor: Colors.white.withValues(alpha: 0.35),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_2_outlined,
                        size: 88, color: AppTheme.darkBackground),
                    const SizedBox(height: 20),
                    Text(
                      'JoinIn',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.darkBackground,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            fontSize: 48,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find Your People. Join Any Event.',
                      style: TextStyle(
                          color: AppTheme.darkBackground,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppTheme.darkBackground,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
