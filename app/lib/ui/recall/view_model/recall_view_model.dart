import 'package:flutter/foundation.dart';

import 'package:book_golas/data/services/recall_service.dart';
import 'package:book_golas/domain/models/recall_models.dart';

class RecallViewModel extends ChangeNotifier {
  final RecallService _recallService = RecallService();

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  RecallSearchResult? _searchResult;
  RecallSearchResult? get searchResult => _searchResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> search(String bookId, String query) async {
    _isSearching = true;
    _searchResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _recallService.search(
        bookId: bookId,
        query: query,
      );

      if (result != null) {
        _searchResult = result;
      } else {
        _errorMessage = '검색 중 오류가 발생했습니다';
      }
    } catch (e) {
      debugPrint('Recall search error: $e');
      _errorMessage = '검색 중 오류가 발생했습니다';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _searchResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
