import 'package:flutter/foundation.dart';

import 'package:book_golas/data/services/recall_service.dart';
import 'package:book_golas/domain/models/recall_models.dart';
import 'package:book_golas/exceptions/subscription_exceptions.dart';

class RecallViewModel extends ChangeNotifier {
  final RecallService _recallService = RecallService();

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  RecallSearchResult? _searchResult;
  RecallSearchResult? get searchResult => _searchResult;

  String? _currentQuery;
  String? get currentQuery => _currentQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<RecallSearchHistory> _recentSearches = [];
  List<RecallSearchHistory> get recentSearches => _recentSearches;

  List<String> _contentSuggestions = [];
  List<String> get contentSuggestions => _contentSuggestions;

  bool _shouldShowPaywall = false;
  int _paywallRemainingUses = 0;

  bool get shouldShowPaywall => _shouldShowPaywall;
  int get paywallRemainingUses => _paywallRemainingUses;

  void clearPaywallState() {
    _shouldShowPaywall = false;
    _paywallRemainingUses = 0;
  }

  Future<void> loadRecentSearches(String bookId) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _recallService.getRecentSearches(bookId: bookId),
        _recallService.getKeywordSuggestions(bookId: bookId),
      ]);
      _recentSearches = results[0] as List<RecallSearchHistory>;
      _contentSuggestions = results[1] as List<String>;
    } catch (e) {
      debugPrint('Failed to load recent searches: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> search(String bookId, String query) async {
    _isSearching = true;
    _searchResult = null;
    _errorMessage = null;
    _currentQuery = query;
    notifyListeners();

    try {
      final result = await _recallService.search(
        bookId: bookId,
        query: query,
      );

      if (result != null) {
        _searchResult = result;
        await loadRecentSearches(bookId);
      } else {
        _errorMessage = '검색 중 오류가 발생했습니다';
      }
    } on AiRecallLimitException catch (e) {
      _errorMessage = e.message;
      _shouldShowPaywall = true;
      _paywallRemainingUses = e.remainingUses;
    } catch (e) {
      debugPrint('Recall search error: $e');
      _errorMessage = '검색 중 오류가 발생했습니다';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void loadFromHistory(RecallSearchHistory history) {
    _currentQuery = history.query;
    _searchResult = history.toSearchResult();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteHistory(String historyId, String bookId) async {
    final success = await _recallService.deleteSearchHistory(historyId);
    if (success) {
      _recentSearches.removeWhere((h) => h.id == historyId);
      notifyListeners();
    }
  }

  void clearResult() {
    _searchResult = null;
    _currentQuery = null;
    _errorMessage = null;
    notifyListeners();
  }
}
