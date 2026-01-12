import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/domain/models/book.dart';

class BookListViewModel extends BaseViewModel {
  StreamSubscription<List<Map<String, dynamic>>>? _booksSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  List<Book> _books = [];
  int _selectedTabIndex = 0;
  bool _showAllCurrentBooks = false;
  bool _isInitialized = false;

  List<Book> get books => _books;
  int get selectedTabIndex => _selectedTabIndex;
  bool get showAllCurrentBooks => _showAllCurrentBooks;

  @override
  bool get isLoading => !_isInitialized || super.isLoading;

  List<Book> get readingBooks => _books
      .where((book) =>
          book.status == BookStatus.reading.value &&
          !(book.currentPage >= book.totalPages && book.totalPages > 0))
      .toList();

  List<Book> get completedBooks => _books
      .where((book) =>
          book.status == BookStatus.completed.value ||
          (book.currentPage >= book.totalPages && book.totalPages > 0))
      .toList();

  BookListViewModel();

  void initialize() {
    if (_isInitialized) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _isInitialized = true;
      _init();
    } else {
      _setupAuthListener();
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

  Future<void> _init() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setLoading(true);

    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _books = (response as List).map((e) => Book.fromJson(e)).toList();
      setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[BookListViewModel] Initial fetch failed: $e');
      setError(e.toString());
      setLoading(false);
      return;
    }

    _booksSubscription = Supabase.instance.client
        .from('books')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (rows) {
            _books = rows.map((e) => Book.fromJson(e)).toList();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('[BookListViewModel] Realtime stream error: $error');
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
      debugPrint('[BookListViewModel] refresh done: ${_books.length} books');
      notifyListeners();
    } catch (e) {
      debugPrint('[BookListViewModel] refresh failed: $e');
    }
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
