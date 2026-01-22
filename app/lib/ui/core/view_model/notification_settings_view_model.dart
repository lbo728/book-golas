import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/data/repositories/notification_settings_repository.dart';
import 'package:book_golas/data/services/notification_settings_service.dart';

class NotificationSettingsViewModel extends BaseViewModel {
  final NotificationSettingsRepository _repository;

  NotificationSettings _settings = NotificationSettings(
    preferredHour: 9,
    preferredMinute: 0,
    notificationEnabled: true,
  );

  NotificationSettings get settings => _settings;

  NotificationSettingsViewModel(this._repository);

  Future<void> loadSettings() async {
    setLoading(true);
    clearError();
    try {
      final loadedSettings = await _repository.loadSettings();
      if (loadedSettings != null) {
        _settings = loadedSettings;
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updatePreferredHour(int hour) async {
    return updatePreferredTime(hour, _settings.preferredMinute);
  }

  Future<bool> updatePreferredTime(int hour, int minute) async {
    if (hour < 0 || hour > 23) {
      setError('Invalid hour: must be 0-23');
      return false;
    }
    if (minute < 0 || minute > 59) {
      setError('Invalid minute: must be 0-59');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      final success = await _repository.updatePreferredTime(hour, minute);
      if (success) {
        _settings =
            _settings.copyWith(preferredHour: hour, preferredMinute: minute);
        notifyListeners();
      }
      return success;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateNotificationEnabled(bool enabled) async {
    setLoading(true);
    clearError();
    try {
      final success = await _repository.updateNotificationEnabled(enabled);
      if (success) {
        _settings = _settings.copyWith(notificationEnabled: enabled);
        notifyListeners();
      }
      return success;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  String getFormattedTime() {
    final hour = _settings.preferredHour;
    final minute = _settings.preferredMinute;

    String hourStr;
    if (hour == 0) {
      hourStr = '오전 12시';
    } else if (hour < 12) {
      hourStr = '오전 $hour시';
    } else if (hour == 12) {
      hourStr = '오후 12시';
    } else {
      hourStr = '오후 ${hour - 12}시';
    }

    if (minute == 0) {
      return hourStr;
    }
    return '$hourStr $minute분';
  }
}
