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
    debugPrint('🔄 [NoteStructureVM] loadStructure 시작: $bookId');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to get existing structure
      debugPrint('🔄 [NoteStructureVM] getStructure 호출...');
      _structure = await _service.getStructure(bookId);
      debugPrint(
          '🔄 [NoteStructureVM] getStructure 결과: ${_structure != null ? "found" : "null"}');

      // If no structure exists, generate new one
      if (_structure == null) {
        debugPrint('🔄 [NoteStructureVM] structureNotes 호출...');
        _structure = await _service.structureNotes(bookId);
        debugPrint(
            '🔄 [NoteStructureVM] structureNotes 결과: ${_structure != null ? "success" : "null"}');
      }

      // Log structure details
      if (_structure != null) {
        debugPrint(
            '🔄 [NoteStructureVM] clusters 개수: ${_structure!.clusters.length}');
      }

      // If still null, set error message
      if (_structure == null) {
        debugPrint('🔄 [NoteStructureVM] 구조화 실패 - null');
        _errorMessage = '노트 구조화에 실패했습니다';
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [NoteStructureVM] 에러: $e');
      debugPrint('🔴 [NoteStructureVM] Stack: $stackTrace');
      _errorMessage = '노트 구조화에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      debugPrint('🔄 [NoteStructureVM] loadStructure 완료, isLoading=false');
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
