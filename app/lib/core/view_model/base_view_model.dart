import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  @protected
  void setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  @protected
  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  @protected
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  @protected
  Future<T?> runAsync<T>(Future<T> Function() action) async {
    if (_isDisposed) return null;
    setLoading(true);
    clearError();
    try {
      final result = await action();
      if (!_isDisposed) {
        setLoading(false);
      }
      return result;
    } catch (e) {
      if (!_isDisposed) {
        setError(e.toString());
        setLoading(false);
      }
      return null;
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
