import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/ui/core/view_model/base_view_model.dart';
import 'package:book_golas/domain/models/book.dart';

class BookListViewModel extends BaseViewModel {
  StreamSubscription<List<Map<String, dynamic>>>? _booksSubscription;

  List<Book> _books = [];
  int _selectedTabIndex = 0;
  bool _showAllCurrentBooks = false;

  List<Book> get books => _books;
  int get selectedTabIndex => _selectedTabIndex;
  bool get showAllCurrentBooks => _showAllCurrentBooks;

  List<Book> get readingBooks =>
      _books.where((book) => book.currentPage < book.totalPages).toList();

  List<Book> get completedBooks =>
      _books.where((book) => book.currentPage >= book.totalPages).toList();

  BookListViewModel() {
    _init();
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
    super.dispose();
  }
}
