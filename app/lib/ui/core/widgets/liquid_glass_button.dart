import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/ui/core/theme/design_system.dart';
import 'pressable_wrapper.dart';

enum LiquidGlassButtonVariant {
  primary,
  secondary,
  destructive,
}

class LiquidGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LiquidGlassButtonVariant variant;
  final bool isFullWidth;
  final Widget? child;

  const LiquidGlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = LiquidGlassButtonVariant.primary,
    this.isFullWidth = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case LiquidGlassButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case LiquidGlassButtonVariant.destructive:
        backgroundColor = AppColors.error;
        textColor = Colors.white;
        break;
      case LiquidGlassButtonVariant.secondary:
        backgroundColor = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);
        textColor = isDark ? Colors.white : Colors.black;
        break;
    }

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: variant == LiquidGlassButtonVariant.secondary
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08))
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: child ??
              Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );

    if (onPressed == null) {
      return Opacity(
        opacity: 0.5,
        child: content,
      );
    }

    return PressableWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed!();
      },
      child: content,
    );
  }
}
