import 'package:shared_preferences/shared_preferences.dart';

class HighlightSettingsService {
  static const String _keyColorIndex = 'highlight_color_index';
  static const String _keyStrokeWidth = 'highlight_stroke_width';
  static const String _keyOpacity = 'highlight_opacity';

  static const int defaultColorIndex = 0;
  static const double defaultStrokeWidth = 8.0;
  static const double defaultOpacity = 0.5;

  static Future<int> getColorIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyColorIndex) ?? defaultColorIndex;
  }

  static Future<void> setColorIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorIndex, index);
  }

  static Future<double> getStrokeWidth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyStrokeWidth) ?? defaultStrokeWidth;
  }

  static Future<void> setStrokeWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyStrokeWidth, width);
  }

  static Future<double> getOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyOpacity) ?? defaultOpacity;
  }

  static Future<void> setOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOpacity, opacity);
  }

  static Future<HighlightSettings> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return HighlightSettings(
      colorIndex: prefs.getInt(_keyColorIndex) ?? defaultColorIndex,
      strokeWidth: prefs.getDouble(_keyStrokeWidth) ?? defaultStrokeWidth,
      opacity: prefs.getDouble(_keyOpacity) ?? defaultOpacity,
    );
  }

  static Future<void> saveAll(HighlightSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_keyColorIndex, settings.colorIndex),
      prefs.setDouble(_keyStrokeWidth, settings.strokeWidth),
      prefs.setDouble(_keyOpacity, settings.opacity),
    ]);
  }
}

class HighlightSettings {
  final int colorIndex;
  final double strokeWidth;
  final double opacity;

  const HighlightSettings({
    required this.colorIndex,
    required this.strokeWidth,
    required this.opacity,
  });
}
