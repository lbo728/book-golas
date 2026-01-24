import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/data/services/aladin_api_service.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/data/services/recommendation_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/core/utils/isbn_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingStartViewModel extends BaseViewModel {
  final BookService _bookService;
  final RecommendationService _recommendationService = RecommendationService();

  Timer? _debounce;

  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;
  BookSearchResult? _selectedBook;
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 14));
  int _currentPageIndex = 0;
  bool _isSaving = false;

  BookStatus _readingStatus = BookStatus.reading;
  DateTime _plannedStartDate = DateTime.now().add(const Duration(days: 1));
  int? _dailyTargetPages;
  Book? _createdBook;
  int? _priority;
  String? _scanError;

  List<BookRecommendation> _recommendations = [];
  bool _isLoadingRecommendations = false;
  RecommendationStats? _recommendationStats;
  String? _recommendationError;
  bool _hasLoadedRecommendations = false;

  List<BookSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  BookSearchResult? get selectedBook => _selectedBook;
  DateTime get startDate => _startDate;
  DateTime get targetDate => _targetDate;
  int get currentPageIndex => _currentPageIndex;
  bool get isSaving => _isSaving;

  BookStatus get readingStatus => _readingStatus;
  DateTime get plannedStartDate => _plannedStartDate;
  int? get dailyTargetPages => _dailyTargetPages;
  Book? get createdBook => _createdBook;
  int? get priority => _priority;
  String? get scanError => _scanError;

  List<BookRecommendation> get recommendations => _recommendations;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  RecommendationStats? get recommendationStats => _recommendationStats;
  String? get recommendationError => _recommendationError;
  bool get hasRecommendations => _recommendations.isNotEmpty;

  /// 실제 사용할 시작일 (상태에 따라 다름)
  DateTime get effectiveStartDate =>
      _readingStatus == BookStatus.planned ? _plannedStartDate : DateTime.now();

  bool get canProceedToSchedule => _selectedBook != null;

  ReadingStartViewModel(this._bookService) {
    _loadRecommendationsIfNeeded();
  }

  Future<void> _loadRecommendationsIfNeeded() async {
    if (_hasLoadedRecommendations) return;
    _hasLoadedRecommendations = true;

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final cached = await _recommendationService.getCachedRecommendations();
      if (cached != null && cached.recommendations.isNotEmpty) {
        _recommendations = cached.recommendations;
        _recommendationStats = cached.stats;
        _isLoadingRecommendations = false;
        notifyListeners();
        return;
      }

      final result = await _recommendationService.getRecommendations();
      if (result.success) {
        _recommendations = result.recommendations;
        _recommendationStats = result.stats;
      } else {
        _recommendationError = result.error;
      }
    } catch (e) {
      _recommendationError = e.toString();
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> refreshRecommendations() async {
    _isLoadingRecommendations = true;
    _recommendationError = null;
    notifyListeners();

    try {
      final result = await _recommendationService.getRecommendations();
      if (result.success) {
        _recommendations = result.recommendations;
        _recommendationStats = result.stats;
      } else {
        _recommendationError = result.error;
      }
    } catch (e) {
      _recommendationError = e.toString();
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  void selectRecommendation(BookRecommendation recommendation) {
    _titleController?.text = recommendation.title;
    _searchBooks(recommendation.title);
  }

  TextEditingController? _titleController;
  void setTitleController(TextEditingController controller) {
    _titleController = controller;
  }

  void onSearchQueryChanged(String query) {
    if (_selectedBook != null) {
      _selectedBook = null;
      notifyListeners();
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        _searchResults = [];
        _isSearching = false;
        notifyListeners();
        return;
      }
      _searchBooks(trimmed);
    });
  }

  Future<void> _searchBooks(String query) async {
    _isSearching = true;
    notifyListeners();

    try {
      final results = await AladinApiService.searchBooks(query);
      _searchResults = results;
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectBook(BookSearchResult book) {
    _selectedBook = book;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBook = null;
    notifyListeners();
  }

  Future<void> searchByISBN(String isbn13) async {
    _isSearching = true;
    _scanError = null;
    notifyListeners();

    try {
      if (!IsbnValidator.isValidISBN13(isbn13)) {
        _scanError = 'ISBN 형식이 올바르지 않습니다';
        _searchResults = [];
        return;
      }

      final result = await AladinApiService.lookupByISBN(isbn13);

      if (result != null) {
        _searchResults = [result];
        _selectedBook = result;
      } else {
        _scanError = '책 정보를 찾을 수 없습니다 ($isbn13)';
        _searchResults = [];
      }
    } catch (e) {
      _scanError = '책 검색에 실패했습니다';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearScanError() {
    _scanError = null;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setTargetDate(DateTime date) {
    _targetDate = date;
    notifyListeners();
  }

  void setReadingStatus(BookStatus status) {
    _readingStatus = status;
    if (status == BookStatus.planned) {
      _targetDate = _plannedStartDate.add(const Duration(days: 14));
    } else {
      _targetDate = DateTime.now().add(const Duration(days: 14));
    }
    notifyListeners();
  }

  void setPlannedStartDate(DateTime date) {
    _plannedStartDate = date;
    if (_readingStatus == BookStatus.planned) {
      _targetDate = date.add(const Duration(days: 14));
    }
    notifyListeners();
  }

  void setPriority(int? priority) {
    _priority = priority;
    notifyListeners();
  }

  /// 하루 목표 페이지 설정
  void setDailyTargetPages(int? pages) {
    _dailyTargetPages = pages;
    notifyListeners();
  }

  void goToSchedulePage() {
    if (_currentPageIndex < 1) {
      _currentPageIndex = 1;
      notifyListeners();
    }
  }

  void goToSearchPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex = 0;
      notifyListeners();
    }
  }

  bool isSameBook(BookSearchResult a, BookSearchResult b) {
    final sameTitle = a.title == b.title;
    final sameAuthor = a.author == b.author;
    final samePages = (a.totalPages ?? -1) == (b.totalPages ?? -1);
    final sameImage = (a.imageUrl ?? '') == (b.imageUrl ?? '');
    return sameTitle && sameAuthor && samePages && sameImage;
  }

  Future<bool> startReading({
    String? fallbackTitle,
    String? fallbackImageUrl,
    int? fallbackTotalPages,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      // 상태에 따라 시작일 결정
      final actualStartDate = _readingStatus == BookStatus.planned
          ? _plannedStartDate
          : DateTime.now();

      final book = Book(
        title: _selectedBook?.title ?? fallbackTitle ?? '',
        author: _selectedBook?.author,
        startDate: actualStartDate,
        targetDate: _targetDate,
        imageUrl: _selectedBook?.imageUrl ?? fallbackImageUrl,
        totalPages: _selectedBook?.totalPages ?? fallbackTotalPages ?? 0,
        status: _readingStatus.value,
        dailyTargetPages: _dailyTargetPages,
        priority: _priority,
        plannedStartDate:
            _readingStatus == BookStatus.planned ? _plannedStartDate : null,
      );

      final bookData = book.toJson();
      bookData['user_id'] = userId;

      final result = await _bookService.addBookWithUserId(bookData);
      if (result != null) {
        _createdBook = result;
        return true;
      }
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
