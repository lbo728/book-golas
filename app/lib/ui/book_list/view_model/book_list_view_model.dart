import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/domain/models/home_display_mode.dart';

class BookListViewModel extends BaseViewModel {
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
      debugPrint('✅ BookListViewModel preferences 프리로드 완료');
    } catch (e) {
      debugPrint('⚠️ BookListViewModel preferences 프리로드 실패: $e');
      _isPreloaded = true;
    }
  }

  StreamSubscription<List<Map<String, dynamic>>>? _booksSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  List<Book> _books = [];
  int _selectedTabIndex = 0;
  bool _showAllCurrentBooks = false;
  bool _isInitialized = false;
  HomeDisplayMode _displayMode = HomeDisplayMode.allBooks;
  String? _selectedBookId;

  List<Book> get books => _books;
  int get selectedTabIndex => _selectedTabIndex;
  bool get showAllCurrentBooks => _showAllCurrentBooks;
  bool get isPreferencesLoaded => _isPreloaded;
  HomeDisplayMode get displayMode => _displayMode;
  String? get selectedBookId => _selectedBookId;

  Book? get selectedBook {
    if (_selectedBookId == null) return null;
    try {
      return _books.firstWhere((b) => b.id == _selectedBookId);
    } catch (_) {
      return null;
    }
  }

  List<Book> get readingBooks =>
      _books.where((book) => book.status == BookStatus.reading.value).toList();

  List<Book> get completedBooks => _books
      .where((book) => book.status == BookStatus.completed.value)
      .toList();

  BookListViewModel() {
    if (_isPreloaded) {
      _displayMode = _preloadedDisplayMode ?? HomeDisplayMode.allBooks;
      _selectedBookId = _preloadedSelectedBookId;
    }
  }

  void initialize() {
    if (_isInitialized) return;

    _loadDisplayMode();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _isInitialized = true;
      _init();
    } else {
      _setupAuthListener();
    }
  }

  void _loadDisplayMode() {
    if (_isPreloaded) {
      _displayMode = _preloadedDisplayMode ?? HomeDisplayMode.allBooks;
      _selectedBookId = _preloadedSelectedBookId;
    }
    notifyListeners();
  }

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
      debugPrint('표시 모드 저장 실패: $e');
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
      debugPrint('선택 책 저장 실패: $e');
    }
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.session?.user.id != null && !_isInitialized) {
          _isInitialized = true;
          _authSubscription?.cancel();
          _authSubscription = null;
          _init();
        }
      },
    );
  }

  void cycleToNextTab() {
    _selectedTabIndex = (_selectedTabIndex + 1) % 4;
    notifyListeners();
  }

  void _init() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setLoading(true);

    _booksSubscription = Supabase.instance.client
        .from('books')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (rows) {
            _books = rows.map((e) => Book.fromJson(e)).toList();
            setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            setError(error.toString());
            setLoading(false);
          },
        );
  }

  void setSelectedTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void toggleShowAllCurrentBooks() {
    _showAllCurrentBooks = !_showAllCurrentBooks;
    notifyListeners();
  }

  Future<void> refresh() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _books = (response as List).map((e) => Book.fromJson(e)).toList();
      print('📚 [BookListViewModel] refresh 완료: ${_books.length}권');
      notifyListeners();
    } catch (e) {
      print('📚 [BookListViewModel] refresh 실패: $e');
    }
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
