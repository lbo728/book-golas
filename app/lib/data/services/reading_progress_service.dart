import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/reading_progress_record.dart';

class ReadingProgressService {
  static final ReadingProgressService _instance =
      ReadingProgressService._internal();
  factory ReadingProgressService() => _instance;
  ReadingProgressService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'reading_progress_history';

  /// 새 진행 기록 추가
  Future<ReadingProgressRecord?> addProgressRecord({
    required String bookId,
    required int currentPage,
    required int previousPage,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('사용자가 로그인되어 있지 않습니다.');
        return null;
      }

      final response = await _supabase
          .from(_tableName)
          .insert({
            'user_id': userId,
            'book_id': bookId,
            'page': currentPage,
            'previous_page': previousPage,
          })
          .select()
          .single();

      return ReadingProgressRecord.fromJson(response);
    } catch (e) {
      print('진행 기록 추가 실패: $e');
      return null;
    }
  }

  /// 특정 책의 진행 히스토리 조회
  Future<List<ReadingProgressRecord>> fetchBookProgressHistory(
      String bookId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('book_id', bookId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ReadingProgressRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('책 진행 히스토리 조회 실패: $e');
      return [];
    }
  }

  /// 현재 사용자의 전체 진행 히스토리 조회
  Future<List<ReadingProgressRecord>> fetchUserProgressHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ReadingProgressRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('사용자 진행 히스토리 조회 실패: $e');
      return [];
    }
  }

  /// 연속 독서일(스트릭) 계산
  Future<int> calculateReadingStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from(_tableName)
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if ((response as List).isEmpty) return 0;

      // 날짜별로 그룹화 (중복 제거)
      final Set<String> readingDates = {};
      for (final record in response) {
        final date = DateTime.parse(record['created_at'] as String);
        final dateKey = '${date.year}-${date.month}-${date.day}';
        readingDates.add(dateKey);
      }

      // 오늘부터 역순으로 연속된 날짜 세기
      int streak = 0;
      final today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      // 오늘 기록이 없으면 어제부터 시작
      final todayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (!readingDates.contains(todayKey)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (true) {
        final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        if (readingDates.contains(dateKey)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('스트릭 계산 실패: $e');
      return 0;
    }
  }

  /// 목표 달성률 계산 (일별 목표 대비 실제 읽은 페이지)
  Future<double> calculateGoalAchievementRate() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      // 활성 책들 가져오기 (완독하지 않은 책)
      final booksResponse = await _supabase
          .from('books')
          .select('id, total_pages, current_page, target_date')
          .eq('user_id', userId);

      if ((booksResponse as List).isEmpty) return 0.0;

      // 일별 목표 합계 계산 (남은 페이지 / 남은 일수)
      int totalDailyTarget = 0;
      for (final book in booksResponse) {
        final totalPages = book['total_pages'] as int? ?? 0;
        final currentPage = book['current_page'] as int? ?? 0;
        final targetDateStr = book['target_date'] as String?;

        if (targetDateStr == null || currentPage >= totalPages) continue;

        final targetDate = DateTime.parse(targetDateStr);
        final targetDay =
            DateTime(targetDate.year, targetDate.month, targetDate.day);
        final daysLeft = targetDay.difference(startOfToday).inDays;

        if (daysLeft <= 0) continue;

        final pagesLeft = totalPages - currentPage;
        final dailyTarget = (pagesLeft / daysLeft).ceil();
        totalDailyTarget += dailyTarget;
      }

      if (totalDailyTarget == 0) return 0.0;

      // 오늘 읽은 페이지 합계
      final progressResponse = await _supabase
          .from(_tableName)
          .select('page, previous_page')
          .eq('user_id', userId)
          .gte('created_at', startOfToday.toIso8601String());

      int todayPagesRead = 0;
      for (final record in progressResponse as List) {
        final page = record['page'] as int;
        final previousPage = record['previous_page'] as int? ?? 0;
        todayPagesRead += (page - previousPage);
      }

      // 달성률 계산 (최대 100%)
      final rate = todayPagesRead / totalDailyTarget;
      return rate > 1.0 ? 1.0 : rate;
    } catch (e) {
      print('목표 달성률 계산 실패: $e');
      return 0.0;
    }
  }

  /// 읽기 통계 가져오기
  Future<Map<String, dynamic>> getReadingStatistics() async {
    try {
      final history = await fetchUserProgressHistory();

      if (history.isEmpty) {
        return {
          'totalPages': 0,
          'averageDaily': 0.0,
          'maxDaily': 0,
          'minDaily': 0,
          'streak': 0,
          'goalRate': 0.0,
        };
      }

      // 일별로 그룹화
      final Map<String, int> dailyPages = {};
      for (final record in history) {
        final dateKey =
            '${record.createdAt.year}-${record.createdAt.month}-${record.createdAt.day}';
        dailyPages[dateKey] = (dailyPages[dateKey] ?? 0) + record.pagesRead;
      }

      final dailyValues = dailyPages.values.toList();
      final totalPages = dailyValues.fold(0, (sum, v) => sum + v);
      final averageDaily =
          dailyValues.isNotEmpty ? totalPages / dailyValues.length : 0.0;
      final maxDaily = dailyValues.isNotEmpty
          ? dailyValues.reduce((a, b) => a > b ? a : b)
          : 0;
      final minDaily = dailyValues.isNotEmpty
          ? dailyValues.reduce((a, b) => a < b ? a : b)
          : 0;

      final streak = await calculateReadingStreak();
      final goalRate = await calculateGoalAchievementRate();

      return {
        'totalPages': totalPages,
        'averageDaily': averageDaily,
        'maxDaily': maxDaily,
        'minDaily': minDaily,
        'streak': streak,
        'goalRate': goalRate,
      };
    } catch (e) {
      print('통계 계산 실패: $e');
      return {
        'totalPages': 0,
        'averageDaily': 0.0,
        'maxDaily': 0,
        'minDaily': 0,
        'streak': 0,
        'goalRate': 0.0,
      };
    }
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchReadingDataForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from(_tableName)
          .select('''
            id,
            book_id,
            page,
            previous_page,
            created_at,
            books!inner (
              id,
              title,
              author,
              image_url,
              status,
              start_date,
              target_date,
              updated_at
            )
          ''')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      final Map<DateTime, List<Map<String, dynamic>>> result = {};

      for (final record in response as List) {
        final createdAt = DateTime.parse(record['created_at'] as String);
        final dateKey =
            DateTime(createdAt.year, createdAt.month, createdAt.day);

        result.putIfAbsent(dateKey, () => []);
        result[dateKey]!.add(record);
      }

      return result;
    } catch (e) {
      debugPrint('기간별 독서 데이터 조회 실패: $e');
      return {};
    }
  }
}
