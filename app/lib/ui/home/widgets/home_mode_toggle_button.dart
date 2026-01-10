import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeModeToggleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final GlobalKey<HomeModeToggleButtonState>? buttonKey;

  const HomeModeToggleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.buttonKey,
  });

  @override
  State<HomeModeToggleButton> createState() => HomeModeToggleButtonState();
}

class HomeModeToggleButtonState extends State<HomeModeToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _brightnessAnimation;
  bool _isLongPressing = false;

  late AnimationController _transitionController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _fadeInAnimation;
  String _displayedLabel = '';

  @override
  void initState() {
    super.initState();
    _displayedLabel = widget.label;

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _brightnessAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _transitionController.addListener(() {
      if (_transitionController.value >= 0.5 &&
          _displayedLabel != widget.label) {
        setState(() {
          _displayedLabel = widget.label;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeModeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void triggerTransitionAnimation() {
    _transitionController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _pressController.reverse().then((_) {
          if (mounted) {
            widget.onTap();
          }
        });
      }
    });
  }

  void _onTapCancel() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_isLongPressing && mounted) {
        _pressController.reverse();
      }
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _isLongPressing = true;
    HapticFeedback.mediumImpact();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isLongPressing = false;
    _pressController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundDecoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: _brightnessAnimation.value),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _transitionController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * math.pi,
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: _transitionController,
                    builder: (context, child) {
                      final opacity = _transitionController.value <= 0.5
                          ? _fadeOutAnimation.value
                          : _fadeInAnimation.value;
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          _displayedLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
