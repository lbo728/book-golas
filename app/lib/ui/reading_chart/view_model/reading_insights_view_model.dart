import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/data/services/reading_insights_service.dart';
import 'package:book_golas/domain/models/reading_insight.dart';

class ReadingInsightsViewModel extends ChangeNotifier {
  final ReadingInsightsService _insightsService;
  final String _userId;

  // State
  bool _isLoading = false;
  List<ReadingInsight>? _insights;
  String? _error;
  bool _canGenerate = false;
  int _bookCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  List<ReadingInsight>? get insights => _insights;
  String? get error => _error;
  bool get canGenerate => _canGenerate;
  int get bookCount => _bookCount;

  ReadingInsightsViewModel({
    required String userId,
    ReadingInsightsService? insightsService,
  })  : _userId = userId,
        _insightsService = insightsService ?? ReadingInsightsService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkBookCount();
    await loadInsight();
  }

  /// 사용자의 완독한 책 개수 확인 및 생성 가능 여부 체크
  Future<void> checkBookCount() async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select('id')
          .eq('user_id', _userId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null);

      _bookCount = (response as List).length;

      // 3권 이상이면 rate limit 확인
      if (_bookCount >= 3) {
        _canGenerate = await _insightsService.canGenerateToday(_userId);
      } else {
        _canGenerate = false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to check book count: $e');
      _canGenerate = false;
      notifyListeners();
    }
  }

  /// 캐시된 인사이트 로드
  Future<void> loadInsight() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedInsights = await _insightsService.getLatestInsight(_userId);
      _insights = cachedInsights;
      _error = null;
    } catch (e) {
      debugPrint('Failed to load insight: $e');
      _error = 'Failed to load insight';
      _insights = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로운 인사이트 생성
  Future<void> generateInsight() async {
    if (!_canGenerate) {
      _error = _bookCount < 3
          ? 'Need at least 3 completed books'
          : 'Already generated today. Try again tomorrow.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newInsights = await _insightsService.generateInsight(_userId);
      _insights = newInsights;
      _error = null;

      // 생성 후 rate limit 활성화 (오늘은 더 이상 생성 불가)
      _canGenerate = false;
    } catch (e) {
      debugPrint('Failed to generate insight: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _insights = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자의 메모리 삭제
  Future<void> clearMemory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _insightsService.clearMemory(_userId);
      _insights = null;
      _error = null;

      // 메모리 삭제 후 생성 가능 여부 재확인
      await checkBookCount();
    } catch (e) {
      debugPrint('Failed to clear memory: $e');
      _error = 'Failed to clear memory';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
