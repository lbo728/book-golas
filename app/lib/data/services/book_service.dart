import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';

class BookService {
  static final BookService _instance = BookService._internal();
  factory BookService() => _instance;
  BookService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'books';

  List<Book> _books = [];
  bool _isLoaded = false;

  List<Book> get books => List.unmodifiable(_books);
  bool get hasBooks => _books.isNotEmpty;
  Book? get latestBook => _books.isNotEmpty ? _books.last : null;

  Future<List<Book>> fetchBooks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _books = (response as List).map((json) => Book.fromJson(json)).toList();

      _isLoaded = true;
      return _books;
    } catch (e) {
      print('책 목록 조회 실패: $e');
      return [];
    }
  }

  Future<Book?> addBook(Book book) async {
    try {
      final bookData = book.toJson();
      bookData.remove('id');
      bookData['created_at'] = DateTime.now().toIso8601String();
      bookData['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await _supabase.from(_tableName).insert(bookData).select().single();

      final newBook = Book.fromJson(response);
      _books.insert(0, newBook);
      return newBook;
    } catch (e) {
      print('책 추가 실패: $e');
      return null;
    }
  }

  Future<Book?> addBookWithUserId(Map<String, dynamic> bookData) async {
    try {
      bookData.remove('id');
      bookData['created_at'] = DateTime.now().toIso8601String();
      bookData['updated_at'] = DateTime.now().toIso8601String();
      final response =
          await _supabase.from(_tableName).insert(bookData).select().single();
      final newBook = Book.fromJson(response);
      _books.insert(0, newBook);
      return newBook;
    } catch (e) {
      print('책 추가 실패: $e');
      return null;
    }
  }

  Future<Book?> updateBook(String bookId, Book book) async {
    try {
      final bookData = book.toJson();
      bookData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .update(bookData)
          .eq('id', bookId)
          .select()
          .single();

      final updatedBook = Book.fromJson(response);

      final index = _books.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        _books[index] = updatedBook;
      }

      return updatedBook;
    } catch (e) {
      print('책 업데이트 실패: $e');
      return null;
    }
  }

  Future<Book?> updateCurrentPage(String bookId, int currentPage) async {
    try {
      // 이전 페이지 가져오기 (히스토리 기록용)
      int previousPage = 0;
      try {
        final existingBook = _books.firstWhere((b) => b.id == bookId);
        previousPage = existingBook.currentPage;
      } catch (_) {
        // 로컬 캐시에 없으면 previousPage = 0
      }

      // books 테이블 업데이트
      final response = await _supabase
          .from(_tableName)
          .update({
            'current_page': currentPage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookId)
          .select()
          .single();

      final updatedBook = Book.fromJson(response);

      // 로컬 캐시 업데이트
      final index = _books.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        _books[index] = updatedBook;
      }

      // 페이지가 증가한 경우에만 히스토리 기록
      if (currentPage > previousPage) {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _supabase.from('reading_progress_history').insert({
            'user_id': userId,
            'book_id': bookId,
            'page': currentPage,
            'previous_page': previousPage,
          });
        }
      }

      return updatedBook;
    } catch (e) {
      print('현재 페이지 업데이트 실패: $e');
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', bookId);

      _books.removeWhere((book) => book.id == bookId);
      return true;
    } catch (e) {
      print('책 삭제 실패: $e');
      return false;
    }
  }

  Future<Book?> getBookById(String bookId) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', bookId).single();

      return Book.fromJson(response);
    } catch (e) {
      print('책 조회 실패: $e');
      return null;
    }
  }

  Future<List<Book>> getActiveBooks() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .lt('current_page', 'total_pages')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('진행 중인 책 조회 실패: $e');
      return [];
    }
  }

  Future<List<Book>> getCompletedBooks() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .gte('current_page', 'total_pages')
          .order('updated_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('완독한 책 조회 실패: $e');
      return [];
    }
  }

  void clearLocalCache() {
    _books.clear();
    _isLoaded = false;
  }

  bool get isLoaded => _isLoaded;
}
