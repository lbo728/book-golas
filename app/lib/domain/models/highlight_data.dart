import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class HighlightRect {
  final double x;
  final double y;
  final double width;
  final double height;

  const HighlightRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory HighlightRect.fromJson(Map<String, dynamic> json) {
    return HighlightRect(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  Rect toRect(Size imageSize) {
    return Rect.fromLTWH(
      x * imageSize.width,
      y * imageSize.height,
      width * imageSize.width,
      height * imageSize.height,
    );
  }

  factory HighlightRect.fromRect(Rect rect, Size imageSize) {
    return HighlightRect(
      x: rect.left / imageSize.width,
      y: rect.top / imageSize.height,
      width: rect.width / imageSize.width,
      height: rect.height / imageSize.height,
    );
  }
}

class HighlightData {
  final String id;
  final HighlightRect rect;
  final String color;
  final double opacity;

  HighlightData({
    String? id,
    required this.rect,
    required this.color,
    this.opacity = 0.4,
  }) : id = id ?? const Uuid().v4();

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    return HighlightData(
      id: json['id'] as String,
      rect: HighlightRect.fromJson(json['rect'] as Map<String, dynamic>),
      color: json['color'] as String,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rect': rect.toJson(),
      'color': color,
      'opacity': opacity,
    };
  }

  Color get colorValue {
    final hexColor = color.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16))
        .withValues(alpha: opacity);
  }

  HighlightData copyWith({
    String? id,
    HighlightRect? rect,
    String? color,
    double? opacity,
  }) {
    return HighlightData(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
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
