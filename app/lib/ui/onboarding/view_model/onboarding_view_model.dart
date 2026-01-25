import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel extends ChangeNotifier {
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding_v1';

  static bool? _preloadedHasSeenOnboarding;
  static bool _isPreloaded = false;

  static Future<void> preloadPreferences() async {
    if (_isPreloaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _preloadedHasSeenOnboarding =
          prefs.getBool(_hasSeenOnboardingKey) ?? false;
      _isPreloaded = true;
      debugPrint(
          'OnboardingViewModel preferences preloaded: $_preloadedHasSeenOnboarding');
    } catch (e) {
      debugPrint('OnboardingViewModel preferences preload failed: $e');
      _isPreloaded = true;
      _preloadedHasSeenOnboarding = false;
    }
  }

  bool _hasSeenOnboarding = false;
  bool _isLoading = true;

  OnboardingViewModel() {
    if (_isPreloaded && _preloadedHasSeenOnboarding != null) {
      _hasSeenOnboarding = _preloadedHasSeenOnboarding!;
      _isLoading = false;
    } else {
      _loadOnboardingStatus();
    }
  }

  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoading => _isLoading;
  bool get shouldShowOnboarding => !_isLoading && !_hasSeenOnboarding;

  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;
    } catch (e) {
      debugPrint('Failed to load onboarding status: $e');
      _hasSeenOnboarding = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenOnboardingKey, true);
      _hasSeenOnboarding = true;
      _preloadedHasSeenOnboarding = true;
      notifyListeners();
      debugPrint('Onboarding completed and saved');
    } catch (e) {
      debugPrint('Failed to save onboarding status: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasSeenOnboardingKey);
      _hasSeenOnboarding = false;
      _preloadedHasSeenOnboarding = false;
      notifyListeners();
      debugPrint('Onboarding reset');
    } catch (e) {
      debugPrint('Failed to reset onboarding: $e');
    }
  }
}
