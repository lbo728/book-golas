import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/highlight_data.dart';

class HighlightPainter extends CustomPainter {
  final List<HighlightData> highlights;
  final List<Offset>? currentDrawingPoints;
  final Color? currentColor;
  final double? currentStrokeWidth;

  HighlightPainter({
    required this.highlights,
    required Size imageSize,
    this.currentDrawingPoints,
    this.currentColor,
    this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final highlight in highlights) {
      if (highlight.points.isEmpty) continue;

      final paint = Paint()
        ..color = highlight.colorValue
        ..strokeWidth = highlight.getScaledStrokeWidth(size)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = highlight.toPath(size);
      canvas.drawPath(path, paint);
    }

    if (currentDrawingPoints != null &&
        currentDrawingPoints!.isNotEmpty &&
        currentColor != null) {
      final paint = Paint()
        ..color = currentColor!
        ..strokeWidth = currentStrokeWidth ?? 20.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(
          currentDrawingPoints!.first.dx, currentDrawingPoints!.first.dy);

      for (int i = 1; i < currentDrawingPoints!.length; i++) {
        path.lineTo(currentDrawingPoints![i].dx, currentDrawingPoints![i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return highlights != oldDelegate.highlights ||
        currentDrawingPoints != oldDelegate.currentDrawingPoints ||
        currentColor != oldDelegate.currentColor;
  }
}
