import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleViewModel extends ChangeNotifier {
  static Locale? _preloadedLocale;
  static bool _isPreloaded = false;

  static Future<void> preloadLocale() async {
    if (_isPreloaded) return;
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('appLocale');
    if (savedLocale != null) {
      _preloadedLocale = Locale(savedLocale);
    } else {
      final systemLocale = PlatformDispatcher.instance.locale;
      _preloadedLocale = ['ko', 'en'].contains(systemLocale.languageCode)
          ? systemLocale
          : const Locale('ko');
    }
    _isPreloaded = true;
  }

  Locale _locale = const Locale('ko');

  Locale get locale => _locale;

  LocaleViewModel() {
    if (_isPreloaded && _preloadedLocale != null) {
      _locale = _preloadedLocale!;
    } else {
      _loadLocale();
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('appLocale');
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    } else {
      final systemLocale = PlatformDispatcher.instance.locale;
      _locale = ['ko', 'en'].contains(systemLocale.languageCode)
          ? systemLocale
          : const Locale('ko');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLocale', locale.languageCode);
  }
}
