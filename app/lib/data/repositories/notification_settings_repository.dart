import 'package:book_golas/data/services/notification_settings_service.dart';

abstract class NotificationSettingsRepository {
  NotificationSettings get settings;

  Future<NotificationSettings?> loadSettings();

  Future<bool> updatePreferredHour(int hour);

  Future<bool> updatePreferredTime(int hour, int minute);

  Future<bool> updateNotificationEnabled(bool enabled);
}

class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  final NotificationSettingsService _service;

  NotificationSettingsRepositoryImpl(this._service);

  @override
  NotificationSettings get settings => _service.settings;

  @override
  Future<NotificationSettings?> loadSettings() => _service.loadSettings();

  @override
  Future<bool> updatePreferredHour(int hour) =>
      _service.updatePreferredHour(hour);

  @override
  Future<bool> updatePreferredTime(int hour, int minute) =>
      _service.updatePreferredTime(hour, minute);

  @override
  Future<bool> updateNotificationEnabled(bool enabled) =>
      _service.updateNotificationEnabled(enabled);
}
