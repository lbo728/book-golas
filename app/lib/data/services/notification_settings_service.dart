import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettings {
  final int preferredHour;
  final int preferredMinute;
  final bool notificationEnabled;

  NotificationSettings({
    required this.preferredHour,
    this.preferredMinute = 0,
    required this.notificationEnabled,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      preferredHour: json['preferred_hour'] ?? 9,
      preferredMinute: json['preferred_minute'] ?? 0,
      notificationEnabled: json['notification_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_hour': preferredHour,
      'preferred_minute': preferredMinute,
      'notification_enabled': notificationEnabled,
    };
  }

  NotificationSettings copyWith({
    int? preferredHour,
    int? preferredMinute,
    bool? notificationEnabled,
  }) {
    return NotificationSettings(
      preferredHour: preferredHour ?? this.preferredHour,
      preferredMinute: preferredMinute ?? this.preferredMinute,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

class NotificationSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  NotificationSettings _settings = NotificationSettings(
    preferredHour: 9,
    notificationEnabled: true,
  );

  NotificationSettings get settings => _settings;

  Future<NotificationSettings?> loadSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('🔔 [NotificationSettings] User not logged in');
      return null;
    }

    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('preferred_hour, preferred_minute, notification_enabled')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _settings = NotificationSettings.fromJson(response);
        debugPrint('🔔 [NotificationSettings] Loaded: $_settings');
        return _settings;
      } else {
        debugPrint(
            '🔔 [NotificationSettings] No settings found, using defaults');
        return _settings;
      }
    } catch (e) {
      debugPrint('🔔 [NotificationSettings] Error loading: $e');
      rethrow;
    }
  }

  Future<bool> updatePreferredHour(int hour) async {
    return updatePreferredTime(hour, _settings.preferredMinute);
  }

  Future<bool> updatePreferredTime(int hour, int minute) async {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('Invalid hour: must be 0-23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError('Invalid minute: must be 0-59');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    try {
      await _supabase.from('fcm_tokens').update({
        'preferred_hour': hour,
        'preferred_minute': minute,
      }).eq('user_id', userId);

      _settings =
          _settings.copyWith(preferredHour: hour, preferredMinute: minute);
      debugPrint(
          '🔔 [NotificationSettings] Updated preferred time to $hour:$minute');
      return true;
    } catch (e) {
      debugPrint('🔔 [NotificationSettings] Error updating time: $e');
      rethrow;
    }
  }

  Future<bool> updateNotificationEnabled(bool enabled) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    try {
      await _supabase
          .from('fcm_tokens')
          .update({'notification_enabled': enabled}).eq('user_id', userId);

      _settings = _settings.copyWith(notificationEnabled: enabled);
      debugPrint(
          '🔔 [NotificationSettings] Updated notification_enabled to $enabled');
      return true;
    } catch (e) {
      debugPrint('🔔 [NotificationSettings] Error updating enabled: $e');
      rethrow;
    }
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
