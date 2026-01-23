import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/domain/models/highlight_data.dart';

class HighlightToolbar extends StatelessWidget {
  final String selectedColor;
  final bool isEraserMode;
  final VoidCallback onUndoTap;
  final bool canUndo;
  final void Function(String color) onColorSelected;
  final void Function(bool isEraser) onEraserModeChanged;

  const HighlightToolbar({
    super.key,
    required this.selectedColor,
    required this.isEraserMode,
    required this.onUndoTap,
    required this.canUndo,
    required this.onColorSelected,
    required this.onEraserModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUndoButton(isDark),
          const SizedBox(width: 8),
          _buildDivider(isDark),
          const SizedBox(width: 8),
          ...HighlightColor.colors
              .map((color) => _buildColorButton(color, isDark)),
          const SizedBox(width: 8),
          _buildDivider(isDark),
          const SizedBox(width: 8),
          _buildEraserButton(isDark),
        ],
      ),
    );
  }

  Widget _buildUndoButton(bool isDark) {
    return GestureDetector(
      onTap: canUndo
          ? () {
              HapticFeedback.lightImpact();
              onUndoTap();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          CupertinoIcons.arrow_uturn_left,
          size: 18,
          color: canUndo
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.grey[600] : Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  Widget _buildColorButton(String colorHex, bool isDark) {
    final isSelected = selectedColor == colorHex && !isEraserMode;
    final color = HighlightColor.toColor(colorHex);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEraserModeChanged(false);
        onColorSelected(colorHex);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildEraserButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEraserModeChanged(!isEraserMode);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEraserMode
              ? const Color(0xFF5B7FFF)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          CupertinoIcons.clear_circled,
          size: 20,
          color: isEraserMode
              ? Colors.white
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
