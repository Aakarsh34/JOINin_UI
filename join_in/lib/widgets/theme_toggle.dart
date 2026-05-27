import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/theme_state.dart';
import '../theme.dart';

/// Animated sun/moon button. Tap to flip between light and dark mode.
/// The icon does a smooth rotate + cross-fade so the transition feels
/// part of the theme change.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final isDark = theme.isEffectivelyDark(context);
    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: context.cs.surfaceContainerLow.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            theme.toggle(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                key: ValueKey<bool>(isDark),
                color: isDark
                    ? AppTheme.primaryAccent
                    : const Color(0xFFFFB300),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
