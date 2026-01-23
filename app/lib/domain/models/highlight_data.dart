import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class HighlightPoint {
  final double x;
  final double y;

  const HighlightPoint({required this.x, required this.y});

  factory HighlightPoint.fromJson(Map<String, dynamic> json) {
    return HighlightPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  Offset toOffset(Size imageSize) {
    return Offset(x * imageSize.width, y * imageSize.height);
  }

  factory HighlightPoint.fromOffset(Offset offset, Size imageSize) {
    return HighlightPoint(
      x: offset.dx / imageSize.width,
      y: offset.dy / imageSize.height,
    );
  }
}

class HighlightData {
  final String id;
  final List<HighlightPoint> points;
  final String color;
  final double opacity;
  final double strokeWidth;

  HighlightData({
    String? id,
    required this.points,
    required this.color,
    this.opacity = 0.5,
    this.strokeWidth = 0.05,
  }) : id = id ?? const Uuid().v4();

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    return HighlightData(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => HighlightPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.5,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.05,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'color': color,
      'opacity': opacity,
      'strokeWidth': strokeWidth,
    };
  }

  Color get colorValue {
    final hexColor = color.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16))
        .withValues(alpha: opacity);
  }

  double getScaledStrokeWidth(Size imageSize) {
    if (strokeWidth > 1.0) {
      return strokeWidth / 400.0 * imageSize.width;
    }
    return strokeWidth * imageSize.width;
  }

  static double normalizeStrokeWidth(double pixelWidth, Size imageSize) {
    return pixelWidth / imageSize.width;
  }

  Path toPath(Size imageSize) {
    if (points.isEmpty) return Path();

    final path = Path();
    final firstPoint = points.first.toOffset(imageSize);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < points.length; i++) {
      final point = points[i].toOffset(imageSize);
      path.lineTo(point.dx, point.dy);
    }

    return path;
  }

  HighlightData copyWith({
    String? id,
    List<HighlightPoint>? points,
    String? color,
    double? opacity,
    double? strokeWidth,
  }) {
    return HighlightData(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  static List<HighlightData> fromJsonList(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .map((item) => HighlightData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<Map<String, dynamic>> toJsonList(List<HighlightData> highlights) {
    return highlights.map((h) => h.toJson()).toList();
  }
}

class HighlightColor {
  static const String yellow = '#FFEB3B';
  static const String orange = '#FF9800';
  static const String pink = '#E91E63';
  static const String blue = '#2196F3';
  static const String green = '#4CAF50';
  static const String purple = '#9C27B0';

  static const List<String> colors = [
    yellow,
    orange,
    pink,
    blue,
    green,
    purple,
  ];

  static Color toColor(String hex) {
    final hexColor = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
