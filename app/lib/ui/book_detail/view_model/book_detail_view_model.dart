import 'package:book_golas/ui/core/view_model/base_view_model.dart';
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
  int _todayPagesRead = 0;

  Book get currentBook => _currentBook;
  int get todayStartPage => _todayStartPage;
  int get todayTargetPage => _todayTargetPage;
  int get attemptCount => _attemptCount;
  Map<String, bool> get dailyAchievements => _dailyAchievements;
  int get todayPagesRead => _todayPagesRead;

  bool get isTodayGoalAchieved {
    final dailyTarget = _currentBook.dailyTargetPages ?? 0;
    if (dailyTarget == 0) return false;
    return _todayPagesRead >= dailyTarget;
  }

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
    try {
      final achievements = <String, bool>{};
      final dailyTarget = _currentBook.dailyTargetPages ?? 0;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('📊 [loadDailyAchievements] userId is null, skipping');
        return;
      }

      print('📊 [loadDailyAchievements] bookId=${_currentBook.id}, dailyTarget=$dailyTarget');

      final response = await Supabase.instance.client
          .from('reading_progress_history')
          .select('page, previous_page, created_at')
          .eq('book_id', _currentBook.id!)
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      print('📊 [loadDailyAchievements] 히스토리 레코드 수: ${(response as List).length}');

      final dailyPages = <String, int>{};
      for (final record in response) {
        final createdAt = DateTime.parse(record['created_at'] as String);
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final pagesRead =
            (record['page'] as int) - (record['previous_page'] as int? ?? 0);
        dailyPages[dateKey] = (dailyPages[dateKey] ?? 0) + pagesRead;
      }

      print('📊 [loadDailyAchievements] 날짜별 페이지: $dailyPages');

      // dailyTarget이 0이면 (null 케이스) 달성 불가로 처리
      if (dailyTarget > 0) {
        for (final entry in dailyPages.entries) {
          achievements[entry.key] = entry.value >= dailyTarget;
        }
      }

      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _todayPagesRead = dailyPages[todayKey] ?? 0;

      print('📊 [loadDailyAchievements] todayKey=$todayKey, todayPagesRead=$_todayPagesRead');
      print('📊 [loadDailyAchievements] achievements=$achievements');

      _dailyAchievements = achievements;
      notifyListeners();
    } catch (e) {
      print('📊 [loadDailyAchievements] 실패: $e');
      _dailyAchievements = {};
      notifyListeners();
    }
  }

  Future<bool> updateCurrentPage(int newPage) async {
    try {
      final previousPage = _currentBook.currentPage;
      print('📖 [ViewModel] 페이지 업데이트 요청: ${_currentBook.title} ($previousPage → $newPage)');
      print('📖 [ViewModel] bookId=${_currentBook.id}, dailyTargetPages=${_currentBook.dailyTargetPages}');

      final updatedBook = await _bookService.updateCurrentPage(
        _currentBook.id!,
        newPage,
        previousPage: previousPage,
      );

      if (updatedBook != null) {
        print('📖 [ViewModel] 업데이트 성공: current_page=${updatedBook.currentPage}');
        _currentBook = updatedBook;

        final pagesRead = newPage - previousPage;
        if (pagesRead > 0) {
          _todayPagesRead += pagesRead;
        }
        print('📖 [ViewModel] todayPagesRead=$_todayPagesRead, isTodayGoalAchieved=$isTodayGoalAchieved');

        await loadDailyAchievements();
        notifyListeners();
        return true;
      }
      print('📖 [ViewModel] 업데이트 실패: updatedBook is null');
      return false;
    } catch (e) {
      print('📖 [ViewModel] 예외 발생: $e');
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
