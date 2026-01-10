import 'package:flutter/material.dart';

class TextHistoryManager {
  final TextEditingController controller;
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  final int maxHistorySize;
  final VoidCallback? onHistoryChanged;

  bool _isUndoing = false;
  String _lastSavedText = '';

  TextHistoryManager({
    required this.controller,
    this.maxHistorySize = 50,
    this.onHistoryChanged,
    String? initialText,
  }) {
    final initial = initialText ?? controller.text;
    _undoStack.add(initial);
    _lastSavedText = initial;
  }

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isUndoing => _isUndoing;

  void saveToHistory() {
    if (_isUndoing) return;

    final currentText = controller.text;
    if (_undoStack.isEmpty || _undoStack.last != currentText) {
      _undoStack.add(currentText);
      _redoStack.clear();
      if (_undoStack.length > maxHistorySize) {
        _undoStack.removeAt(0);
      }
      _lastSavedText = currentText;
      onHistoryChanged?.call();
    }
  }

  void saveIfChanged() {
    final currentText = controller.text;
    if (currentText != _lastSavedText) {
      saveToHistory();
    }
  }

  bool undo() {
    if (!canUndo) return false;

    _isUndoing = true;
    final currentText = controller.text;

    if (_undoStack.last == currentText && _undoStack.length > 1) {
      _redoStack.add(_undoStack.removeLast());
    } else if (_undoStack.last != currentText) {
      _redoStack.add(currentText);
    }

    if (_undoStack.isNotEmpty) {
      final previousText = _undoStack.last;
      controller.text = previousText;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: previousText.length),
      );
      _lastSavedText = previousText;
    }

    _isUndoing = false;
    onHistoryChanged?.call();
    return true;
  }

  bool redo() {
    if (!canRedo) return false;

    _isUndoing = true;
    final nextText = _redoStack.removeLast();
    _undoStack.add(nextText);
    controller.text = nextText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: nextText.length),
    );
    _lastSavedText = nextText;
    _isUndoing = false;
    onHistoryChanged?.call();
    return true;
  }

  void clear() {
    saveToHistory();
    controller.clear();
    _lastSavedText = '';
    onHistoryChanged?.call();
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.add(controller.text);
    _lastSavedText = controller.text;
    onHistoryChanged?.call();
  }
}
