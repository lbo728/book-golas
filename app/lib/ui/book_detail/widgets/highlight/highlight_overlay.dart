import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/domain/models/highlight_data.dart';
import 'highlight_painter.dart';

class HighlightOverlay extends StatefulWidget {
  final Size imageSize;
  final List<HighlightData> highlights;
  final String selectedColor;
  final double selectedOpacity;
  final double strokeWidth;
  final bool isEraserMode;
  final void Function(HighlightData highlight) onHighlightAdded;
  final void Function(String highlightId) onHighlightRemoved;

  const HighlightOverlay({
    super.key,
    required this.imageSize,
    required this.highlights,
    required this.selectedColor,
    this.selectedOpacity = 0.5,
    this.strokeWidth = 20.0,
    required this.isEraserMode,
    required this.onHighlightAdded,
    required this.onHighlightRemoved,
  });

  @override
  State<HighlightOverlay> createState() => _HighlightOverlayState();
}

class _HighlightOverlayState extends State<HighlightOverlay> {
  List<Offset> _currentPoints = [];

  Color get _currentColor {
    return HighlightColor.toColor(widget.selectedColor)
        .withValues(alpha: widget.selectedOpacity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: widget.isEraserMode ? _onTapForEraser : null,
      child: CustomPaint(
        painter: HighlightPainter(
          highlights: widget.highlights,
          imageSize: widget.imageSize,
          currentDrawingPoints: widget.isEraserMode ? null : _currentPoints,
          currentColor: _currentColor,
          currentStrokeWidth: widget.strokeWidth,
        ),
        size: widget.imageSize,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.isEraserMode) return;

    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isEraserMode) return;

    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isEraserMode) return;

    if (_currentPoints.length >= 2) {
      HapticFeedback.lightImpact();

      final points = _currentPoints
          .map((offset) => HighlightPoint.fromOffset(offset, widget.imageSize))
          .toList();

      final highlight = HighlightData(
        points: points,
        color: widget.selectedColor,
        opacity: widget.selectedOpacity,
        strokeWidth: widget.strokeWidth,
      );

      widget.onHighlightAdded(highlight);
    }

    setState(() {
      _currentPoints = [];
    });
  }

  void _onTapForEraser(TapUpDetails details) {
    final tapPoint = details.localPosition;

    for (final highlight in widget.highlights.reversed) {
      final path = highlight.toPath(widget.imageSize);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight.strokeWidth + 20;

      if (_isPointNearPath(tapPoint, path, highlight.strokeWidth + 20)) {
        HapticFeedback.mediumImpact();
        widget.onHighlightRemoved(highlight.id);
        return;
      }
    }
  }

  bool _isPointNearPath(Offset point, Path path, double tolerance) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      for (double t = 0; t <= metric.length; t += 5) {
        final tangent = metric.getTangentForOffset(t);
        if (tangent != null) {
          final distance = (tangent.position - point).distance;
          if (distance <= tolerance) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
