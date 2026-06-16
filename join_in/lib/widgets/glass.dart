import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Soft, blurred gradient orbs that sit behind screen content for depth.
/// Wrapped in [IgnorePointer] so it never blocks taps.
class AmbientOrbs extends StatelessWidget {
  const AmbientOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -70,
            child: _BlurOrb(
              color: AppTheme.primaryAccent
                  .withValues(alpha: isDark ? 0.20 : 0.14),
              size: 300,
            ),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: _BlurOrb(
              color: AppTheme.secondaryAccent
                  .withValues(alpha: isDark ? 0.16 : 0.10),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 40,
            right: -40,
            child: _BlurOrb(
              color: AppTheme.primaryAccent
                  .withValues(alpha: isDark ? 0.10 : 0.08),
              size: 180,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Frosted-glass surface: backdrop blur + translucent tint + soft border.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppMetrics.radiusLg)),
    this.blur = AppMetrics.glassBlur,
    this.padding,
    this.margin,
    this.tint,
    this.borderColor,
    this.showShimmer = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final Color? borderColor;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fill = tint ??
        (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.72));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.85));

    Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (showShimmer) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: const _GlassShimmerOverlay(),
            ),
          ),
        ],
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

/// A slow, subtle light sweep across glass surfaces.
class _GlassShimmerOverlay extends StatefulWidget {
  const _GlassShimmerOverlay();

  @override
  State<_GlassShimmerOverlay> createState() => _GlassShimmerOverlayState();
}

class _GlassShimmerOverlayState extends State<_GlassShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShimmerPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = size.width * 0.45;
    final left = -sweep + (size.width + sweep * 2) * progress;
    final rect = Rect.fromLTWH(left, 0, sweep, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

/// Opinionated glass card — frosted surface with optional shimmer on load.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppMetrics.radiusLg)),
    this.padding = const EdgeInsets.all(AppMetrics.cardPadding),
    this.margin,
    this.shimmer = false,
    this.onTap,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool shimmer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = GlassSurface(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      showShimmer: shimmer,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: AppTheme.primaryAccent.withValues(alpha: 0.12),
          highlightColor: AppTheme.primaryAccent.withValues(alpha: 0.06),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Circular frosted icon button used in app bars and tool rows.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? context.cs.onSurface;
    return Tooltip(
      message: tooltip ?? '',
      child: GlassSurface(
        borderRadius: BorderRadius.circular(size / 2),
        blur: 14,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: iconColor, size: size * 0.48),
            ),
          ),
        ),
      ),
    );
  }
}
