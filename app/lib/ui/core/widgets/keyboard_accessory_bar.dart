import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyboardAccessoryBar extends StatelessWidget {
  final VoidCallback onDone;
  final bool isDark;
  final IconData? icon;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final bool showNavigation;
  final bool canGoUp;
  final bool canGoDown;

  const KeyboardAccessoryBar({
    super.key,
    required this.onDone,
    required this.isDark,
    this.icon,
    this.onUp,
    this.onDown,
    this.showNavigation = false,
    this.canGoUp = true,
    this.canGoDown = true,
  });

  Widget _buildGlassButton({
    required VoidCallback? onTap,
    required IconData iconData,
    bool enabled = true,
  }) {
    final effectiveAlpha = enabled ? 1.0 : 0.3;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: (isDark ? 0.15 : 0.6) * effectiveAlpha),
                  Colors.white.withValues(alpha: (isDark ? 0.08 : 0.3) * effectiveAlpha),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: (isDark ? 0.2 : 0.4) * effectiveAlpha),
                width: 1,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              iconData,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9 * effectiveAlpha)
                  : Colors.black.withValues(alpha: 0.7 * effectiveAlpha),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: showNavigation ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          if (showNavigation) ...[
            Row(
              children: [
                _buildGlassButton(
                  onTap: onUp,
                  iconData: CupertinoIcons.chevron_up,
                  enabled: canGoUp && onUp != null,
                ),
                const SizedBox(width: 8),
                _buildGlassButton(
                  onTap: onDown,
                  iconData: CupertinoIcons.chevron_down,
                  enabled: canGoDown && onDown != null,
                ),
              ],
            ),
          ],
          _buildGlassButton(
            onTap: onDone,
            iconData: icon ?? CupertinoIcons.keyboard_chevron_compact_down,
          ),
        ],
      ),
    );
  }
}
