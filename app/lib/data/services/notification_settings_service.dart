import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettings {
  final int preferredHour;
  final bool notificationEnabled;

  NotificationSettings({
    required this.preferredHour,
    required this.notificationEnabled,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      preferredHour: json['preferred_hour'] ?? 9,
      notificationEnabled: json['notification_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_hour': preferredHour,
      'notification_enabled': notificationEnabled,
    };
  }

  NotificationSettings copyWith({
    int? preferredHour,
    bool? notificationEnabled,
  }) {
    return NotificationSettings(
      preferredHour: preferredHour ?? this.preferredHour,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

class NotificationSettingsService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  NotificationSettings _settings = NotificationSettings(
    preferredHour: 9,
    notificationEnabled: true,
  );

  bool _isLoading = false;
  String? _error;

  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('🔔 [NotificationSettings] User not logged in');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('preferred_hour, notification_enabled')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _settings = NotificationSettings.fromJson(response);
        debugPrint('🔔 [NotificationSettings] Loaded: $_settings');
      } else {
        debugPrint('🔔 [NotificationSettings] No settings found, using defaults');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('🔔 [NotificationSettings] Error loading: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreferredHour(int hour) async {
    if (hour < 0 || hour > 23) {
      _error = 'Invalid hour: must be 0-23';
      notifyListeners();
      return false;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase
          .from('fcm_tokens')
          .update({'preferred_hour': hour})
          .eq('user_id', userId);

      _settings = _settings.copyWith(preferredHour: hour);
      debugPrint('🔔 [NotificationSettings] Updated preferred_hour to $hour');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔔 [NotificationSettings] Error updating hour: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotificationEnabled(bool enabled) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase
          .from('fcm_tokens')
          .update({'notification_enabled': enabled})
          .eq('user_id', userId);

      _settings = _settings.copyWith(notificationEnabled: enabled);
      debugPrint('🔔 [NotificationSettings] Updated notification_enabled to $enabled');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔔 [NotificationSettings] Error updating enabled: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getFormattedTime() {
    final hour = _settings.preferredHour;
    if (hour == 0) return '오전 12시';
    if (hour < 12) return '오전 ${hour}시';
    if (hour == 12) return '오후 12시';
    return '오후 ${hour - 12}시';
  }

  static List<Map<String, dynamic>> getAvailableHours() {
    return List.generate(24, (index) {
      String label;
      if (index == 0) {
        label = '오전 12시';
      } else if (index < 12) {
        label = '오전 $index시';
      } else if (index == 12) {
        label = '오후 12시';
      } else {
        label = '오후 ${index - 12}시';
      }
      return {'hour': index, 'label': label};
    });
  }
}
