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

  Widget _buildIconButton({
    required VoidCallback? onTap,
    required IconData iconData,
    bool enabled = true,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final effectiveAlpha = enabled ? 1.0 : 0.3;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.only(
          left: isFirst ? 12 : 8,
          right: isLast ? 12 : 8,
          top: 10,
          bottom: 10,
        ),
        child: Icon(
          iconData,
          size: 20,
          color: isDark
              ? Colors.white.withValues(alpha: 0.9 * effectiveAlpha)
              : Colors.black.withValues(alpha: 0.7 * effectiveAlpha),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showNavigation) ...[
                      _buildIconButton(
                        onTap: onUp,
                        iconData: CupertinoIcons.chevron_up,
                        enabled: canGoUp && onUp != null,
                        isFirst: true,
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      _buildIconButton(
                        onTap: onDown,
                        iconData: CupertinoIcons.chevron_down,
                        enabled: canGoDown && onDown != null,
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ],
                    _buildIconButton(
                      onTap: onDone,
                      iconData: icon ?? CupertinoIcons.keyboard_chevron_compact_down,
                      isFirst: !showNavigation,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
