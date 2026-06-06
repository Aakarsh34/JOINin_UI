import 'dart:async';

import 'package:flutter/material.dart';

/// A lightweight, dependency-free animation toolkit shared across the app so
/// every screen gets the same polished entrance + tactile feel.
///
/// The two primitives here are intentionally small and composable:
/// - [FadeSlideIn] plays a one-shot fade + slide-up when a widget mounts; pass
///   a staggered [delay] (e.g. `index * 50ms`) to cascade list items.
/// - [Pressable] adds a subtle scale-down while the user is pressing, without
///   intercepting the child's own tap/scroll gestures.

/// Fades and slides its [child] in once, when first built. Designed to be cheap
/// enough to wrap every list item / section header in the app.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.08),
  });

  final Widget child;

  /// Delay before the entrance starts — use `Duration(milliseconds: index * 50)`
  /// to stagger a list.
  final Duration delay;

  final Duration duration;
  final Curve curve;

  /// Starting offset expressed as a fraction of the child's size. The default
  /// nudges the child up from 8% below its final spot.
  final Offset beginOffset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fade = curved;
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(curved);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _startTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps a child so it scales down slightly while pressed, giving buttons,
/// cards and tiles a tactile feel. Uses a [Listener] so it never swallows the
/// child's own gestures (InkWell ripples, taps and list scrolling all keep
/// working).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
