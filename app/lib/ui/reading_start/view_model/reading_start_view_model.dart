import 'dart:async';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/data/services/aladin_api_service.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingStartViewModel extends BaseViewModel {
  final BookService _bookService;

  Timer? _debounce;

  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;
  BookSearchResult? _selectedBook;
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 14));
  int _currentPageIndex = 0;
  bool _isSaving = false;

  // 새로 추가: 독서 상태 관련
  BookStatus _readingStatus = BookStatus.reading;
  DateTime _plannedStartDate = DateTime.now().add(const Duration(days: 1));
  int? _dailyTargetPages;
  Book? _createdBook;

  List<BookSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  BookSearchResult? get selectedBook => _selectedBook;
  DateTime get startDate => _startDate;
  DateTime get targetDate => _targetDate;
  int get currentPageIndex => _currentPageIndex;
  bool get isSaving => _isSaving;

  // 새로 추가: 독서 상태 관련 getters
  BookStatus get readingStatus => _readingStatus;
  DateTime get plannedStartDate => _plannedStartDate;
  int? get dailyTargetPages => _dailyTargetPages;
  Book? get createdBook => _createdBook;

  /// 실제 사용할 시작일 (상태에 따라 다름)
  DateTime get effectiveStartDate =>
      _readingStatus == BookStatus.planned ? _plannedStartDate : DateTime.now();

  bool get canProceedToSchedule => _selectedBook != null;

  ReadingStartViewModel(this._bookService);

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

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setTargetDate(DateTime date) {
    _targetDate = date;
    notifyListeners();
  }

  /// 독서 상태 설정 (읽을 예정 / 바로 시작)
  void setReadingStatus(BookStatus status) {
    _readingStatus = status;
    notifyListeners();
  }

  /// 계획된 시작일 설정 (읽을 예정일 때 사용)
  void setPlannedStartDate(DateTime date) {
    _plannedStartDate = date;
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
