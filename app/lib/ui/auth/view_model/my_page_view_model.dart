import 'dart:io';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';

class MyPageViewModel extends BaseViewModel {
  bool _isEditingNickname = false;
  File? _pendingAvatarFile;

  bool get isEditingNickname => _isEditingNickname;
  File? get pendingAvatarFile => _pendingAvatarFile;

  void startEditingNickname() {
    _isEditingNickname = true;
    notifyListeners();
  }

  void cancelEditingNickname() {
    _isEditingNickname = false;
    notifyListeners();
  }

  void finishEditingNickname() {
    _isEditingNickname = false;
    notifyListeners();
  }

  void setPendingAvatarFile(File? file) {
    _pendingAvatarFile = file;
    notifyListeners();
  }

  void clearPendingAvatarFile() {
    _pendingAvatarFile = null;
    notifyListeners();
  }

  void reset() {
    _isEditingNickname = false;
    _pendingAvatarFile = null;
    notifyListeners();
  }
}
