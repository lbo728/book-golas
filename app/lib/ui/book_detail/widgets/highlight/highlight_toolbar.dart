import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/domain/models/highlight_data.dart';

class HighlightToolbar extends StatelessWidget {
  final String selectedColor;
  final double selectedOpacity;
  final bool isEraserMode;
  final VoidCallback onUndoTap;
  final bool canUndo;
  final void Function(String color) onColorSelected;
  final void Function(double opacity) onOpacityChanged;
  final void Function(bool isEraser) onEraserModeChanged;

  const HighlightToolbar({
    super.key,
    required this.selectedColor,
    this.selectedOpacity = 0.5,
    required this.isEraserMode,
    required this.onUndoTap,
    required this.canUndo,
    required this.onColorSelected,
    required this.onOpacityChanged,
    required this.onEraserModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          const SizedBox(height: 8),
          _buildOpacitySlider(isDark),
        ],
      ),
    );
  }

  Widget _buildOpacitySlider(bool isDark) {
    final color = HighlightColor.toColor(selectedColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.sun_min,
          size: 16,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        SizedBox(
          width: 180,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color.withValues(alpha: selectedOpacity),
              inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: selectedOpacity,
              min: 0.1,
              max: 0.8,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onOpacityChanged(value);
              },
            ),
          ),
        ),
        Icon(
          CupertinoIcons.sun_max_fill,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ],
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
