import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/reading_goal.dart';

class ReadingGoalService {
  static final ReadingGoalService _instance = ReadingGoalService._internal();
  factory ReadingGoalService() => _instance;
  ReadingGoalService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'reading_goals';

  ReadingGoal? _currentYearGoal;

  ReadingGoal? get currentYearGoal => _currentYearGoal;

  Future<ReadingGoal?> getCurrentYearGoal() async {
    final year = DateTime.now().year;
    return getYearGoal(year);
  }

  Future<ReadingGoal?> getYearGoal(int year) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .maybeSingle();

      if (response == null) return null;

      final goal = ReadingGoal.fromJson(response);
      if (year == DateTime.now().year) {
        _currentYearGoal = goal;
      }
      return goal;
    } catch (e) {
      debugPrint('연간 목표 조회 실패: $e');
      return null;
    }
  }

  Future<ReadingGoal?> setYearlyGoal({
    required int year,
    required int targetBooks,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final existingGoal = await getYearGoal(year);

      if (existingGoal != null) {
        final response = await _supabase
            .from(_tableName)
            .update({
              'target_books': targetBooks,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingGoal.id!)
            .select()
            .single();

        final updatedGoal = ReadingGoal.fromJson(response);
        if (year == DateTime.now().year) {
          _currentYearGoal = updatedGoal;
        }
        return updatedGoal;
      } else {
        final response = await _supabase
            .from(_tableName)
            .insert({
              'user_id': userId,
              'year': year,
              'target_books': targetBooks,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        final newGoal = ReadingGoal.fromJson(response);
        if (year == DateTime.now().year) {
          _currentYearGoal = newGoal;
        }
        return newGoal;
      }
    } catch (e) {
      debugPrint('연간 목표 설정 실패: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getYearlyProgress({int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return _emptyProgress();
      }

      final goal = await getYearGoal(targetYear);
      final targetBooks = goal?.targetBooks ?? 0;

      final startOfYear = DateTime(targetYear, 1, 1);
      final endOfYear = DateTime(targetYear, 12, 31, 23, 59, 59);

      final response = await _supabase
          .from('books')
          .select('id, updated_at')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .gte('updated_at', startOfYear.toIso8601String())
          .lte('updated_at', endOfYear.toIso8601String());

      final completedBooks = (response as List).length;

      final progressRate = targetBooks > 0
          ? (completedBooks / targetBooks).clamp(0.0, 1.0)
          : 0.0;

      final remainingBooks =
          targetBooks > completedBooks ? targetBooks - completedBooks : 0;

      final now = DateTime.now();
      final daysLeftInYear = targetYear == now.year
          ? endOfYear.difference(now).inDays + 1
          : (targetYear > now.year ? 365 : 0);

      final booksPerMonth = daysLeftInYear > 0 && remainingBooks > 0
          ? (remainingBooks / (daysLeftInYear / 30)).ceil()
          : 0;

      return {
        'targetBooks': targetBooks,
        'completedBooks': completedBooks,
        'remainingBooks': remainingBooks,
        'progressRate': progressRate,
        'daysLeftInYear': daysLeftInYear,
        'booksPerMonth': booksPerMonth,
        'isOnTrack': _isOnTrack(targetBooks, completedBooks, targetYear),
      };
    } catch (e) {
      debugPrint('연간 진행률 조회 실패: $e');
      return _emptyProgress();
    }
  }

  bool _isOnTrack(int targetBooks, int completedBooks, int year) {
    if (targetBooks == 0) return true;

    final now = DateTime.now();
    if (year != now.year) return completedBooks >= targetBooks;

    final dayOfYear = now.difference(DateTime(year, 1, 1)).inDays + 1;
    final expectedBooks = (targetBooks * dayOfYear / 365).floor();

    return completedBooks >= expectedBooks;
  }

  Map<String, dynamic> _emptyProgress() {
    return {
      'targetBooks': 0,
      'completedBooks': 0,
      'remainingBooks': 0,
      'progressRate': 0.0,
      'daysLeftInYear': 0,
      'booksPerMonth': 0,
      'isOnTrack': true,
    };
  }

  void clearLocalCache() {
    _currentYearGoal = null;
  }
}
