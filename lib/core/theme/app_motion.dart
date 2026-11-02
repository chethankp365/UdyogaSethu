import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UdyogaSethu Motion & Micro-interaction Tokens & Widgets.
/// Designed for smooth, purposeful animations that feel premium, responsive,
/// and respectful of low-end hardware and reduced-motion user preferences.
class AppMotion {
  AppMotion._();

  // Durations
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration entrance = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration staggerStep = Duration(milliseconds: 45);

  // Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;

  /// Checks whether animations are disabled in the system or context.
  static bool areAnimationsDisabled(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}

/// A tactile wrapper widget that applies a subtle, delightful scale feedback
/// (down to 0.97) when tapped, giving all buttons and cards an authentic,
/// native tactile feel. Respects reduced-motion settings and haptic feedback.
class BouncingPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final bool enableHaptics;
  final BorderRadius? borderRadius;

  const BouncingPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
    this.enableHaptics = true,
    this.borderRadius,
  });

  @override
  State<BouncingPressable> createState() => _BouncingPressableState();
}

class _BouncingPressableState extends State<BouncingPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      reverseDuration: AppMotion.standard,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _isPressed = true;
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = AppMotion.areAnimationsDisabled(context);
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    if (disabled) {
      return InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius,
        child: widget.child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A lightweight, staggered entrance animation widget that gracefully slides
/// and fades in its child widget (e.g. for cards in a list or dashboard tiles).
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final double slideOffset;
  final Axis axis;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = AppMotion.entrance,
    this.slideOffset = 18.0,
    this.axis = Axis.vertical,
  });

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    );

    final offset = widget.axis == Axis.vertical
        ? Offset(0.0, widget.slideOffset)
        : Offset(widget.slideOffset, 0.0);

    _slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    ));

    final effectiveDelay = widget.delay + (AppMotion.staggerStep * widget.index);
    if (effectiveDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(effectiveDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.areAnimationsDisabled(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A soft, elegant pulsating glow for high-priority badges, active statuses,
/// or live SOS/Voice indicators.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final double minBlur;
  final Duration duration;

  const PulseGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.maxBlur = 12.0,
    this.minBlur = 2.0,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.areAnimationsDisabled(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final currentBlur = widget.minBlur + (widget.maxBlur - widget.minBlur) * t;
        final alpha = (0.2 + (0.35 * t)).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: alpha),
                blurRadius: currentBlur,
                spreadRadius: currentBlur * 0.35,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
