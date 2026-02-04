import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:book_golas/data/repositories/book_repository.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/domain/models/home_display_mode.dart';

class HomeViewModel extends ChangeNotifier {
  static const String _displayModeKey = 'home_display_mode';
  static const String _selectedBookIdKey = 'selected_reading_book_id';

  static HomeDisplayMode? _preloadedDisplayMode;
  static String? _preloadedSelectedBookId;
  static bool _isPreloaded = false;

  static Future<void> preloadPreferences() async {
    if (_isPreloaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_displayModeKey);
      _preloadedDisplayMode = HomeDisplayMode.fromString(savedMode);
      _preloadedSelectedBookId = prefs.getString(_selectedBookIdKey);
      _isPreloaded = true;
      debugPrint('HomeViewModel preferences preloaded');
    } catch (e) {
      debugPrint('HomeViewModel preferences preload failed: $e');
      _isPreloaded = true;
    }
  }

  final BookRepository _bookRepository;

  HomeDisplayMode _displayMode = HomeDisplayMode.allBooks;
  String? _selectedBookId;
  bool _isLoading = false;
  String? _errorMessage;

  HomeViewModel(this._bookRepository) {
    if (_isPreloaded) {
      _displayMode = _preloadedDisplayMode ?? HomeDisplayMode.allBooks;
      _selectedBookId = _preloadedSelectedBookId;
    }
  }

  bool get isPreferencesLoaded => _isPreloaded;
  HomeDisplayMode get displayMode => _displayMode;
  String? get selectedBookId => _selectedBookId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Book> get books => _bookRepository.cachedBooks;
  bool get hasBooks => _bookRepository.hasBooks;
  Book? get latestBook => _bookRepository.latestBook;

  Book? get selectedBook {
    if (_selectedBookId == null) return null;
    try {
      return books.firstWhere((b) => b.id == _selectedBookId);
    } catch (_) {
      return null;
    }
  }

  List<Book> get readingBooks => books
      .where((book) =>
          book.status == BookStatus.reading.value &&
          !(book.currentPage >= book.totalPages && book.totalPages > 0))
      .toList();

  Future<void> setDisplayMode(HomeDisplayMode mode) async {
    _displayMode = mode;
    if (mode == HomeDisplayMode.allBooks) {
      _selectedBookId = null;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayModeKey, mode.value);
      if (mode == HomeDisplayMode.allBooks) {
        await prefs.remove(_selectedBookIdKey);
      }
    } catch (e) {
      debugPrint('Failed to save display mode: $e');
    }
  }

  Future<void> setSelectedBook(String bookId) async {
    _selectedBookId = bookId;
    _displayMode = HomeDisplayMode.readingDetail;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedBookIdKey, bookId);
      await prefs.setString(
          _displayModeKey, HomeDisplayMode.readingDetail.value);
    } catch (e) {
      debugPrint('Failed to save selected book: $e');
    }
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookRepository.getBooks();
    } catch (e) {
      _errorMessage = '책 목록을 불러오는데 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getDaysPassed(Book book) {
    return DateTime.now().difference(book.startDate).inDays;
  }

  int getTotalDays(Book book) {
    return book.targetDate.difference(book.startDate).inDays;
  }

  double getProgressPercentage(Book book) {
    final daysPassed = getDaysPassed(book);
    final totalDays = getTotalDays(book);
    return totalDays > 0 ? (daysPassed / totalDays * 100).clamp(0, 100) : 0;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
