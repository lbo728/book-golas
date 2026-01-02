import 'package:book_golas/core/view_model/base_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingProgressViewModel extends BaseViewModel {
  String _bookId;

  List<Map<String, dynamic>>? _progressHistory;

  List<Map<String, dynamic>>? get progressHistory => _progressHistory;

  ReadingProgressViewModel({required String bookId}) : _bookId = bookId;

  void updateBookId(String bookId) {
    _bookId = bookId;
  }

  Future<List<Map<String, dynamic>>> fetchProgressHistory() async {
    setLoading(true);
    try {
      final response = await Supabase.instance.client
          .from('reading_progress')
          .select()
          .eq('book_id', _bookId)
          .order('created_at', ascending: true);

      _progressHistory = (response as List).cast<Map<String, dynamic>>();
      notifyListeners();
      return _progressHistory!;
    } catch (e) {
      setError('진행 기록을 불러오는데 실패했습니다: $e');
      return [];
    } finally {
      setLoading(false);
    }
  }

  List<Map<String, dynamic>> getRecentProgress({int limit = 7}) {
    if (_progressHistory == null) return [];
    final count = _progressHistory!.length;
    if (count <= limit) return _progressHistory!;
    return _progressHistory!.sublist(count - limit);
  }

  int getTotalPagesRead() {
    if (_progressHistory == null || _progressHistory!.isEmpty) return 0;
    return _progressHistory!.fold<int>(0, (sum, record) {
      final pages = record['pages_read'] as int? ?? 0;
      return sum + pages;
    });
  }

  double getAveragePagesPerDay() {
    if (_progressHistory == null || _progressHistory!.isEmpty) return 0;
    final total = getTotalPagesRead();
    return total / _progressHistory!.length;
  }

  int getReadingStreak() {
    if (_progressHistory == null || _progressHistory!.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = _progressHistory!.length - 1; i >= 0; i--) {
      final record = _progressHistory![i];
      final createdAt = DateTime.tryParse(record['created_at'] ?? '');
      if (createdAt == null) continue;

      final recordDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final expectedDate = today.subtract(Duration(days: streak));

      if (recordDate == expectedDate) {
        streak++;
      } else if (recordDate.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  Future<bool> addProgressRecord({
    required int pagesRead,
    required int currentPage,
    String? note,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setError('로그인이 필요합니다');
        return false;
      }

      await Supabase.instance.client.from('reading_progress').insert({
        'book_id': _bookId,
        'user_id': userId,
        'pages_read': pagesRead,
        'current_page': currentPage,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchProgressHistory();
      return true;
    } catch (e) {
      setError('진행 기록 추가에 실패했습니다: $e');
      return false;
    }
  }
}
