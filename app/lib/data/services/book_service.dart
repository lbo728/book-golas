import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/utils/subscription_utils.dart';
import 'package:book_golas/exceptions/subscription_exceptions.dart';

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
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      _books = (response as List).map((json) => Book.fromJson(json)).toList();

      _isLoaded = true;
      return _books;
    } catch (e) {
      debugPrint('책 목록 조회 실패: $e');
      return [];
    }
  }

  Future<Book?> addBook(Book book) async {
    // Check concurrent reading limit for free users
    if (!await SubscriptionUtils.canAddMoreConcurrentBooks(_books.length)) {
      throw ConcurrentReadingLimitException(
        '동시 읽기 제한에 도달했습니다. Pro 업그레이드로 무제한 이용하세요.',
      );
    }

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
      debugPrint('책 추가 실패: $e');
      return null;
    }
  }

  Future<Book?> addBookWithUserId(Map<String, dynamic> bookData) async {
    // Check concurrent reading limit for free users
    if (!await SubscriptionUtils.canAddMoreConcurrentBooks(_books.length)) {
      throw ConcurrentReadingLimitException(
        '동시 읽기 제한에 도달했습니다. Pro 업그레이드로 무제한 이용하세요.',
      );
    }

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
      debugPrint('책 추가 실패: $e');
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
      debugPrint('책 업데이트 실패: $e');
      return null;
    }
  }

  Future<Book?> updateCurrentPage(
    String bookId,
    int currentPage, {
    int? previousPage,
  }) async {
    try {
      int prevPage = previousPage ?? 0;
      if (previousPage == null) {
        try {
          final existingBook = _books.firstWhere((b) => b.id == bookId);
          prevPage = existingBook.currentPage;
        } catch (_) {}
      }

      debugPrint(
          '📖 [BookService] 페이지 업데이트 시작: bookId=$bookId, $prevPage → $currentPage');

      final response = await _supabase
          .from(_tableName)
          .update({
            'current_page': currentPage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookId)
          .select()
          .single();

      var updatedBook = Book.fromJson(response);
      debugPrint(
          '📖 [BookService] DB 업데이트 성공: current_page=${updatedBook.currentPage}');

      if (updatedBook.currentPage >= updatedBook.totalPages &&
          updatedBook.totalPages > 0 &&
          updatedBook.status != BookStatus.completed.value) {
        try {
          final statusResponse = await _supabase
              .from(_tableName)
              .update({
                'status': BookStatus.completed.value,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bookId)
              .select()
              .single();
          updatedBook = Book.fromJson(statusResponse);
          debugPrint(
              '📖 [BookService] 완독 상태로 변경: status=${updatedBook.status}');
        } catch (statusError) {
          debugPrint('📖 [BookService] 완독 상태 변경 실패 (무시됨): $statusError');
        }
      }

      final index = _books.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        _books[index] = updatedBook;
      } else {
        _books.add(updatedBook);
      }

      if (currentPage > prevPage) {
        try {
          final userId = _supabase.auth.currentUser?.id;
          if (userId != null) {
            await _supabase.from('reading_progress_history').insert({
              'user_id': userId,
              'book_id': bookId,
              'page': currentPage,
              'previous_page': prevPage,
            });
            debugPrint('📖 [BookService] 히스토리 기록 성공: $prevPage → $currentPage');
          }
        } catch (historyError) {
          debugPrint('📖 [BookService] 히스토리 기록 실패 (무시됨): $historyError');
        }
      }

      return updatedBook;
    } catch (e) {
      debugPrint('📖 [BookService] 페이지 업데이트 실패: $e');
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      await _supabase.from(_tableName).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookId);

      _books.removeWhere((book) => book.id == bookId);
      return true;
    } catch (e) {
      debugPrint('책 삭제 실패: $e');
      return false;
    }
  }

  Future<Book?> getBookById(String bookId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', bookId)
          .isFilter('deleted_at', null)
          .single();

      return Book.fromJson(response);
    } catch (e) {
      debugPrint('책 조회 실패: $e');
      return null;
    }
  }

  Future<List<Book>> getActiveBooks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('status', 'reading')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      debugPrint('진행 중인 책 조회 실패: $e');
      return [];
    }
  }

  Future<List<Book>> getCompletedBooks() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .gte('current_page', 'total_pages')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      debugPrint('완독한 책 조회 실패: $e');
      return [];
    }
  }

  Future<Book?> pauseReading(String bookId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'status': BookStatus.willRetry.value,
            'paused_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('독서 중단 실패: $e');
      return null;
    }
  }

  Future<Book?> resumeReading(
    String bookId, {
    DateTime? newTargetDate,
    bool incrementAttempt = true,
  }) async {
    try {
      final currentBook = await getBookById(bookId);
      if (currentBook == null) return null;

      final updateData = <String, dynamic>{
        'status': BookStatus.reading.value,
        'paused_at': null,
        'start_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newTargetDate != null) {
        updateData['target_date'] = newTargetDate.toIso8601String();
      }

      if (incrementAttempt) {
        updateData['attempt_count'] = currentBook.attemptCount + 1;
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
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
      debugPrint('독서 재개 실패: $e');
      return null;
    }
  }

  Future<Book?> updatePriority(String bookId, int? priority) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'priority': priority,
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('우선순위 업데이트 실패: $e');
      return null;
    }
  }

  Future<Book?> updatePlannedStartDate(String bookId, DateTime? date) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'planned_start_date': date?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('예정 시작일 업데이트 실패: $e');
      return null;
    }
  }

  void clearLocalCache() {
    _books.clear();
    _isLoaded = false;
  }

  bool get isLoaded => _isLoaded;

  Future<Book?> updateRatingAndReview(
    String bookId, {
    required int rating,
    String? review,
  }) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'rating': rating,
            'review': review,
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('별점/한줄평 업데이트 실패: $e');
      return null;
    }
  }

  Future<Book?> updateReviewLink(String bookId, String? reviewLink) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'review_link': reviewLink,
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('독후감 링크 업데이트 실패: $e');
      return null;
    }
  }

  Future<Book?> updateLongReview(String bookId, String? longReview) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({
            'long_review': longReview,
            'updated_at': DateTime.now().toIso8601String(),
          })
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
      debugPrint('독후감 업데이트 실패: $e');
      return null;
    }
  }

  Future<int> getCompletedBooksCount({int? year}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      var query = _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('status', BookStatus.completed.value)
          .isFilter('deleted_at', null);

      if (year != null) {
        final startOfYear = DateTime(year, 1, 1);
        final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
        query = query
            .gte('updated_at', startOfYear.toIso8601String())
            .lte('updated_at', endOfYear.toIso8601String());
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      debugPrint('완독 책 개수 조회 실패: $e');
      return 0;
    }
  }
}
