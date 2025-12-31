import 'package:book_golas/core/view_model/base_view_model.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookDetailViewModel extends BaseViewModel {
  final BookService _bookService;

  Book _currentBook;
  int _todayStartPage = 0;
  int _todayTargetPage = 0;
  int _attemptCount = 1;
  Map<String, bool> _dailyAchievements = {};

  Book get currentBook => _currentBook;
  int get todayStartPage => _todayStartPage;
  int get todayTargetPage => _todayTargetPage;
  int get attemptCount => _attemptCount;
  Map<String, bool> get dailyAchievements => _dailyAchievements;

  int get daysLeft {
    final now = DateTime.now();
    final target = _currentBook.targetDate;
    final days = target.difference(now).inDays;
    return days >= 0 ? days + 1 : days;
  }

  double get progressPercentage {
    if (_currentBook.totalPages == 0) return 0;
    return (_currentBook.currentPage / _currentBook.totalPages * 100).clamp(0, 100);
  }

  int get pagesLeft => (_currentBook.totalPages - _currentBook.currentPage)
      .clamp(0, _currentBook.totalPages);

  String get attemptEncouragement {
    switch (_attemptCount) {
      case 1:
        return '최고!';
      case 2:
        return '잘하고 있다';
      case 3:
        return '화이팅!';
      default:
        return '내가 더 도와줄게...';
    }
  }

  BookDetailViewModel({
    required BookService bookService,
    required Book initialBook,
  })  : _bookService = bookService,
        _currentBook = initialBook,
        _attemptCount = initialBook.attemptCount {
    _todayStartPage = initialBook.startDate.day;
    _todayTargetPage = initialBook.targetDate.day;
  }

  Future<void> loadDailyAchievements() async {
    final achievements = <String, bool>{};
    final startDate = _currentBook.startDate;
    final now = DateTime.now();

    for (var i = 0; i < now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      achievements[dateKey] = i % 3 != 1;
    }

    _dailyAchievements = achievements;
    notifyListeners();
  }

  Future<bool> updateCurrentPage(int newPage) async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .update({
            'current_page': newPage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentBook.id!)
          .select()
          .single();

      if (response['id'] != null) {
        _currentBook = _currentBook.copyWith(currentPage: newPage);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('페이지 업데이트에 실패했습니다: $e');
      return false;
    }
  }

  Future<bool> updateTargetDate(DateTime newDate, int newAttempt) async {
    try {
      final newDailyTarget = calculateDailyTargetPages(
        currentPage: _currentBook.currentPage,
        totalPages: _currentBook.totalPages,
        targetDate: newDate,
      );

      final response = await Supabase.instance.client
          .from('books')
          .update({
            'target_date': newDate.toIso8601String(),
            'attempt_count': newAttempt,
            'daily_target_pages': newDailyTarget,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentBook.id!)
          .select()
          .single();

      if (response['id'] != null) {
        _currentBook = _currentBook.copyWith(
          targetDate: newDate,
          attemptCount: newAttempt,
          dailyTargetPages: newDailyTarget,
        );
        _attemptCount = newAttempt;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('목표일 업데이트에 실패했습니다: $e');
      return false;
    }
  }

  int calculateDailyTargetPages({
    required int currentPage,
    required int totalPages,
    required DateTime targetDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final daysRemaining = target.difference(today).inDays + 1;

    if (daysRemaining <= 0) return 0;

    final pagesRemaining = totalPages - currentPage;
    if (pagesRemaining <= 0) return 0;

    return (pagesRemaining / daysRemaining).ceil();
  }

  void updateBook(Book book) {
    _currentBook = book;
    notifyListeners();
  }
}
