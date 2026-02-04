import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContextMenuItem<T> {
  final String label;
  final T value;
  final IconData? icon;

  const ContextMenuItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

class LiquidGlassContextMenu<T> extends StatefulWidget {
  final VoidCallback onDismiss;
  final ValueChanged<T> onItemSelected;
  final Offset position;
  final List<ContextMenuItem<T>> items;

  const LiquidGlassContextMenu({
    super.key,
    required this.onDismiss,
    required this.onItemSelected,
    required this.position,
    required this.items,
  });

  @override
  State<LiquidGlassContextMenu<T>> createState() =>
      _LiquidGlassContextMenuState<T>();
}

class _LiquidGlassContextMenuState<T> extends State<LiquidGlassContextMenu<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  void _selectItem(T value) {
    HapticFeedback.selectionClick();
    _animationController.reverse().then((_) {
      widget.onDismiss();
      widget.onItemSelected(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                color:
                    Colors.black.withValues(alpha: _fadeAnimation.value * 0.3),
              ),
            ),
            Positioned(
              right: 16,
              top: widget.position.dy + 8,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth - 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topRight,
                    child: _buildMenu(isDark),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenu(bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildMenuItems(isDark),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.7);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    final List<Widget> items = [];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];

      items.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectItem(item.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      color: iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (i < widget.items.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              color: dividerColor,
            ),
          ),
        );
      }
    }

    return items;
  }
}

void showLiquidGlassContextMenu<T>(
  BuildContext context, {
  required Offset position,
  required List<ContextMenuItem<T>> items,
  required ValueChanged<T> onItemSelected,
}) {
  HapticFeedback.selectionClick();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => LiquidGlassContextMenu<T>(
      onDismiss: () {
        entry.remove();
      },
      onItemSelected: onItemSelected,
      position: position,
      items: items,
    ),
  );

  Overlay.of(context).insert(entry);
}
