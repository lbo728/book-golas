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
  int? _activePointerId;
  int _pointerCount = 0;

  Color get _currentColor {
    return HighlightColor.toColor(widget.selectedColor)
        .withValues(alpha: widget.selectedOpacity);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
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
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;

    if (_pointerCount > 1) {
      _cancelDrawing();
      return;
    }

    if (widget.isEraserMode) return;

    _activePointerId = event.pointer;
    setState(() {
      _currentPoints = [event.localPosition];
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerCount > 1) return;
    if (widget.isEraserMode) return;
    if (_activePointerId != event.pointer) return;

    setState(() {
      _currentPoints.add(event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerCount--;

    if (event.pointer != _activePointerId) return;

    if (!widget.isEraserMode && _currentPoints.length >= 2) {
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

    _resetDrawing();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerCount--;
    if (event.pointer == _activePointerId) {
      _resetDrawing();
    }
  }

  void _cancelDrawing() {
    setState(() {
      _currentPoints = [];
    });
  }

  void _resetDrawing() {
    setState(() {
      _currentPoints = [];
      _activePointerId = null;
    });
  }

  void _onTapForEraser(TapUpDetails details) {
    final tapPoint = details.localPosition;

    for (final highlight in widget.highlights.reversed) {
      final path = highlight.toPath(widget.imageSize);

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
