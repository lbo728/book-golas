import 'package:flutter/foundation.dart';

import 'package:book_golas/domain/models/note_structure_models.dart';
import 'package:book_golas/data/services/note_structure_service.dart';

class NoteStructureViewModel extends ChangeNotifier {
  final NoteStructureService _service;

  bool _isLoading = false;
  NoteStructure? _structure;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  NoteStructure? get structure => _structure;
  String? get errorMessage => _errorMessage;

  NoteStructureViewModel({required NoteStructureService service})
      : _service = service;

  /// Load existing structure or generate new one if not found
  Future<void> loadStructure(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to get existing structure
      _structure = await _service.getStructure(bookId);

      // If no structure exists, generate new one
      if (_structure == null) {
        _structure = await _service.structureNotes(bookId);
      }

      // If still null, set error message
      if (_structure == null) {
        _errorMessage = '노트 구조화에 실패했습니다';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Regenerate structure (always calls structureNotes)
  Future<void> regenerateStructure(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _structure = await _service.structureNotes(bookId);

      if (_structure == null) {
        _errorMessage = '노트 구조화에 실패했습니다';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
