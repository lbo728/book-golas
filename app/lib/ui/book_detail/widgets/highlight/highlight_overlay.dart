import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/domain/models/highlight_data.dart';
import 'highlight_painter.dart';

class HighlightOverlay extends StatefulWidget {
  final Size imageSize;
  final List<HighlightData> highlights;
  final String selectedColor;
  final double selectedOpacity;
  final bool isEraserMode;
  final void Function(HighlightData highlight) onHighlightAdded;
  final void Function(String highlightId) onHighlightRemoved;

  const HighlightOverlay({
    super.key,
    required this.imageSize,
    required this.highlights,
    required this.selectedColor,
    this.selectedOpacity = 0.4,
    required this.isEraserMode,
    required this.onHighlightAdded,
    required this.onHighlightRemoved,
  });

  @override
  State<HighlightOverlay> createState() => _HighlightOverlayState();
}

class _HighlightOverlayState extends State<HighlightOverlay> {
  Offset? _startPoint;
  Offset? _currentPoint;

  Rect? get _currentRect {
    if (_startPoint == null || _currentPoint == null) return null;
    return Rect.fromPoints(_startPoint!, _currentPoint!);
  }

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
          currentDrawingRect: widget.isEraserMode ? null : _currentRect,
          currentColor: _currentColor,
        ),
        size: widget.imageSize,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.isEraserMode) return;

    setState(() {
      _startPoint = details.localPosition;
      _currentPoint = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isEraserMode) return;

    setState(() {
      _currentPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isEraserMode) return;

    final rect = _currentRect;
    if (rect != null && rect.width > 10 && rect.height > 10) {
      HapticFeedback.lightImpact();
      final normalizedRect = HighlightRect.fromRect(rect, widget.imageSize);
      final highlight = HighlightData(
        rect: normalizedRect,
        color: widget.selectedColor,
        opacity: widget.selectedOpacity,
      );
      widget.onHighlightAdded(highlight);
    }

    setState(() {
      _startPoint = null;
      _currentPoint = null;
    });
  }

  void _onTapForEraser(TapUpDetails details) {
    final tapPoint = details.localPosition;

    for (final highlight in widget.highlights.reversed) {
      final rect = highlight.rect.toRect(widget.imageSize);
      if (rect.contains(tapPoint)) {
        HapticFeedback.mediumImpact();
        widget.onHighlightRemoved(highlight.id);
        return;
      }
    }
  }
}
