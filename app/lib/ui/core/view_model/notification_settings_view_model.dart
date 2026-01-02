import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/data/repositories/notification_settings_repository.dart';
import 'package:book_golas/data/services/notification_settings_service.dart';

class NotificationSettingsViewModel extends BaseViewModel {
  final NotificationSettingsRepository _repository;

  NotificationSettings _settings = NotificationSettings(
    preferredHour: 9,
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
    if (hour < 0 || hour > 23) {
      setError('Invalid hour: must be 0-23');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      final success = await _repository.updatePreferredHour(hour);
      if (success) {
        _settings = _settings.copyWith(preferredHour: hour);
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
    if (hour == 0) return '오전 12시';
    if (hour < 12) return '오전 $hour시';
    if (hour == 12) return '오후 12시';
    return '오후 ${hour - 12}시';
  }
}
