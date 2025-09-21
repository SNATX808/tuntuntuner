import 'dart:async';
import 'package:flutter/material.dart';

class PressableSquare extends StatefulWidget {
  final double size;
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double darkenAmount;
  final Duration releaseDuration;
  final Duration flashDuration;
  final BorderRadius? borderRadius;

  const PressableSquare({
    super.key,
    required this.size,
    required this.child,
    required this.onTap,
    this.color = Colors.white,
    this.darkenAmount = 0.2,
    this.releaseDuration = const Duration(milliseconds: 120),
    this.flashDuration = const Duration(milliseconds: 100),
    this.borderRadius,
  });

  @override
  State<PressableSquare> createState() => _PressableSquareState();
}

class _PressableSquareState extends State<PressableSquare> {
  bool _pressed = false;
  bool _flashing = false;

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Future<void> _triggerFlash() async {
    if (!mounted) return;
    setState(() => _flashing = true);
    await Future.delayed(widget.flashDuration);
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color;
    final held = _darken(base, widget.darkenAmount);
    final showDark = _pressed || _flashing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _triggerFlash();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: widget.releaseDuration,
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: showDark ? held : base,
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
