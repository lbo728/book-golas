import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/highlight_data.dart';

class HighlightPainter extends CustomPainter {
  final List<HighlightData> highlights;
  final Size imageSize;
  final Rect? currentDrawingRect;
  final Color? currentColor;

  HighlightPainter({
    required this.highlights,
    required this.imageSize,
    this.currentDrawingRect,
    this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final highlight in highlights) {
      final paint = Paint()
        ..color = highlight.colorValue
        ..style = PaintingStyle.fill;

      final rect = highlight.rect.toRect(imageSize);
      canvas.drawRect(rect, paint);
    }

    if (currentDrawingRect != null && currentColor != null) {
      final paint = Paint()
        ..color = currentColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, paint);

      final borderPaint = Paint()
        ..color = currentColor!.withValues(alpha: 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(currentDrawingRect!, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.highlights != highlights ||
        oldDelegate.currentDrawingRect != currentDrawingRect ||
        oldDelegate.imageSize != imageSize;
  }
}
