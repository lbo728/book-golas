import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:collection';
import 'package:book_golas/data/services/reading_progress_service.dart';
import 'package:book_golas/data/services/reading_goal_service.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/genre_analysis_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/monthly_books_chart.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/annual_goal_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/reading_streak_heatmap.dart';
import 'package:book_golas/ui/reading_chart/widgets/sheets/reading_goal_sheet.dart';
import 'package:book_golas/ui/core/widgets/liquid_glass_tab_bar.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/ai_insight_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/completion_rate_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/highlight_stats_card.dart';
import 'package:book_golas/ui/reading_chart/view_model/reading_insights_view_model.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:provider/provider.dart';

enum TimeFilter { daily, weekly, monthly }

class ReadingChartScreen extends StatefulWidget {
  const ReadingChartScreen({super.key});

  static final GlobalKey<_ReadingChartScreenState> globalKey =
      GlobalKey<_ReadingChartScreenState>();

  static void cycleToNextTab() {
    globalKey.currentState?.cycleToNextTab();
  }

  @override
  State<ReadingChartScreen> createState() => _ReadingChartScreenState();
}

class _ReadingChartScreenState extends State<ReadingChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeFilter _selectedFilter = TimeFilter.daily;
  final ReadingProgressService _progressService = ReadingProgressService();
  final ReadingGoalService _goalService = ReadingGoalService();
  final BookService _bookService = BookService();

  List<Map<String, dynamic>>? _cachedRawData;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, int> _genreDistribution = {};
  Map<int, int> _monthlyBookCount = {};
  Map<String, dynamic> _goalProgress = {};
  Map<DateTime, int> _heatmapData = {};

  int _totalStarted = 0;
  int _completedBooks = 0;
  int _abandonedBooks = 0;
  int _inProgressBooks = 0;
  double _completionRate = 0.0;
  double _abandonRate = 0.0;
  double _retrySuccessRate = 0.0;

  int _totalHighlights = 0;
  int _totalNotes = 0;
  int _totalPhotos = 0;
  Map<String, int> _highlightGenreDistribution = {};
  List<String> _topKeywords = [];

  int _selectedSectionIndex = 0;
  final _sectionKeys = List.generate(5, (_) => GlobalKey());
  final ScrollController _analysisScrollController = ScrollController();
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analysisScrollController.addListener(_updateSelectedSectionOnScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _analysisScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void cycleToNextTab() {
    final nextIndex = (_tabController.index + 1) % 3;
    _tabController.animateTo(nextIndex);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentYear = DateTime.now().year;
      final results = await Future.wait([
        fetchUserProgressHistory(),
        _progressService.getGenreDistribution(year: currentYear),
        _progressService.getMonthlyBookCount(year: currentYear),
        _goalService.getYearlyProgress(year: currentYear),
        _progressService.getDailyReadingHeatmap(weeksToShow: 26),
        _calculateCompletionStats(),
        _calculateHighlightStats(),
      ]);

      if (mounted) {
        setState(() {
          _cachedRawData = results[0] as List<Map<String, dynamic>>;
          _genreDistribution = results[1] as Map<String, int>;
          _monthlyBookCount = results[2] as Map<int, int>;
          _goalProgress = results[3] as Map<String, dynamic>;
          _heatmapData = results[4] as Map<DateTime, int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calculateCompletionStats() async {
    final books = await _bookService.fetchBooks();

    final startedBooks = books.where((b) => b.status != 'planned').toList();
    final completed = books.where((b) => b.status == 'completed').length;
    final reading = books.where((b) => b.status == 'reading').length;
    final willRetry = books.where((b) => b.status == 'will_retry').length;

    final totalStarted = startedBooks.length;

    _totalStarted = totalStarted;
    _completedBooks = completed;
    _abandonedBooks = willRetry;
    _inProgressBooks = reading;
    _completionRate = totalStarted > 0 ? (completed / totalStarted * 100) : 0.0;
    _abandonRate = totalStarted > 0 ? (willRetry / totalStarted * 100) : 0.0;

    final retriedBooks = books
        .where((b) => b.status == 'completed' && b.attemptCount > 1)
        .length;
    _retrySuccessRate = willRetry > 0 ? (retriedBooks / willRetry * 100) : 0.0;
  }

  Future<void> _calculateHighlightStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('book_images')
        .select('id, extracted_text, highlights, book_id')
        .eq('user_id', user.id);

    final images = response as List<Map<String, dynamic>>;

    _totalPhotos = images.length;

    int highlightCount = 0;
    int noteCount = 0;
    final Map<String, int> genreCount = {};
    final Map<String, int> wordFrequency = {};

    for (final image in images) {
      final highlights = image['highlights'] as List?;
      if (highlights != null && highlights.isNotEmpty) {
        highlightCount += highlights.length;
      }

      final extractedText = image['extracted_text'] as String?;
      if (extractedText != null && extractedText.trim().isNotEmpty) {
        noteCount++;

        final words = extractedText
            .split(RegExp(r'[\s,.\!?\(\)\[\]]+'))
            .where((w) => w.length > 1)
            .toList();
        for (final word in words) {
          wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
        }
      }
    }

    final books = await _bookService.fetchBooks();
    final bookGenreMap = {for (var b in books) b.id: b.genre};

    for (final image in images) {
      final bookId = image['book_id'] as String?;
      if (bookId != null) {
        final genre = bookGenreMap[bookId];
        if (genre != null && genre.isNotEmpty) {
          genreCount[genre] = (genreCount[genre] ?? 0) + 1;
        }
      }
    }

    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _totalHighlights = highlightCount;
    _totalNotes = noteCount;
    _highlightGenreDistribution = genreCount;
    _topKeywords = sortedWords.take(5).map((e) => e.key).toList();
  }

  Future<List<Map<String, dynamic>>> fetchUserProgressHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('reading_progress_history')
        .select('page, book_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (e) => {
            'page': e['page'] as int,
            'book_id': e['book_id'] as String?,
            'created_at': DateTime.parse(e['created_at'] as String),
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> aggregateByDate(
    List<Map<String, dynamic>> data,
    TimeFilter filter,
  ) {
    if (data.isEmpty) return [];

    final SplayTreeMap<DateTime, Map<String, int>> dateData = SplayTreeMap();

    for (final entry in data) {
      final createdAt = entry['created_at'] as DateTime;
      DateTime key;

      switch (filter) {
        case TimeFilter.daily:
          key = DateTime(createdAt.year, createdAt.month, createdAt.day);
          break;
        case TimeFilter.weekly:
          final weekday = createdAt.weekday;
          final diff = weekday - 1;
          key = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          ).subtract(Duration(days: diff));
          break;
        case TimeFilter.monthly:
          key = DateTime(createdAt.year, createdAt.month, 1);
          break;
      }

      final page = entry['page'] as int;
      final bookId = entry['book_id'] as String?;

      if (!dateData.containsKey(key)) {
        dateData[key] = {};
      }

      if (bookId != null) {
        dateData[key]![bookId] = (dateData[key]![bookId] ?? 0) < page
            ? page
            : dateData[key]![bookId]!;
      }
    }

    int cumulativePages = 0;
    final result = <Map<String, dynamic>>[];

    for (final entry in dateData.entries) {
      final dailyTotal = entry.value.values.fold<int>(
        0,
        (sum, page) => sum + page,
      );
      cumulativePages += dailyTotal;

      result.add({
        'date': entry.key,
        'cumulative_page': cumulativePages,
        'daily_page': dailyTotal,
      });
    }

    return result;
  }

  Map<String, dynamic> calculateStatistics(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {
        'total_pages': 0,
        'average_daily': 0.0,
        'max_daily': 0,
        'min_daily': 0,
      };
    }

    final dailyPages = data.map((e) => e['daily_page'] as int).toList();
    final totalPages = data.last['cumulative_page'] as int;
    final averageDaily = dailyPages.isEmpty
        ? 0.0
        : dailyPages.reduce((a, b) => a + b) / dailyPages.length;
    final maxDaily = dailyPages.reduce((a, b) => a > b ? a : b);
    final minDaily = dailyPages.reduce((a, b) => a < b ? a : b);

    return {
      'total_pages': totalPages,
      'average_daily': averageDaily,
      'max_daily': maxDaily,
      'min_daily': minDaily,
    };
  }

  int _calculateStreak(List<Map<String, dynamic>> aggregatedData) {
    if (aggregatedData.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final sortedDates = aggregatedData
        .map((e) => e['date'] as DateTime)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    DateTime expectedDate = todayNormalized;

    if (sortedDates.isEmpty ||
        !_isSameDay(sortedDates.first, todayNormalized)) {
      expectedDate = todayNormalized.subtract(const Duration(days: 1));
    }

    for (final date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (_isSameDay(normalizedDate, expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (normalizedDate.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<double> _calculateGoalRate() async {
    return await _progressService.calculateGoalAchievementRate();
  }

  void _showGoalSheet(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final result = await ReadingGoalSheet.show(
      context: context,
      year: currentYear,
      currentGoal: _goalProgress['targetBooks'] as int?,
    );

    if (result != null && mounted) {
      await _goalService.setYearlyGoal(year: currentYear, targetBooks: result);
      _loadData();
    }
  }

  void _scrollToSection(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });

    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _navigateToMemorablePages(BuildContext context) async {
    final books = await _bookService.fetchBooks();
    if (books.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('book_images')
        .select('book_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return;

    final recentBookId = response.first['book_id'] as String;
    final book = books.firstWhere(
      (b) => b.id == recentBookId,
      orElse: () => books.first,
    );

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
  }

  void _updateSelectedSectionOnScroll() {
    if (_tabController.index != 1) return;

    if (_scrollDebounce?.isActive ?? false) _scrollDebounce!.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 10), () {
      final scrollPosition = _analysisScrollController.position.pixels;
      final maxScroll = _analysisScrollController.position.maxScrollExtent;

      if (scrollPosition >= maxScroll - 50) {
        if (_selectedSectionIndex != _sectionKeys.length - 1) {
          setState(() {
            _selectedSectionIndex = _sectionKeys.length - 1;
          });
        }
        return;
      }

      int closestIndex = 0;
      double closestDistance = double.infinity;
      final screenCenter = 300.0;

      for (int i = 0; i < _sectionKeys.length; i++) {
        final context = _sectionKeys[i].currentContext;
        if (context == null) continue;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) continue;

        final position = renderBox.localToGlobal(Offset.zero);
        final sectionTop = position.dy;
        final sectionCenter = sectionTop + (renderBox.size.height / 2);
        final distance = (sectionCenter - screenCenter).abs();

        if (distance < closestDistance) {
          closestDistance = distance;
          closestIndex = i;
        }
      }

      if (_selectedSectionIndex != closestIndex) {
        setState(() {
          _selectedSectionIndex = closestIndex;
        });
      }
    });
  }

  String _getFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.daily:
        return '일별';
      case TimeFilter.weekly:
        return '주별';
      case TimeFilter.monthly:
        return '월별';
    }
  }

  String _formatDate(DateTime date, TimeFilter filter) {
    switch (filter) {
      case TimeFilter.daily:
        return '${date.month}/${date.day}';
      case TimeFilter.weekly:
        return '${date.month}/${date.day}';
      case TimeFilter.monthly:
        return '${date.year}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
        elevation: 0,
        title: const Text('나의 독서 상태'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        bottom: LiquidGlassTabBar(
          controller: _tabController,
          tabs: const ['개요', '분석', '활동'],
        ),
      ),
      body: SafeArea(child: _buildContent(isDark)),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '데이터를 불러올 수 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final rawData = _cachedRawData ?? [];
    final aggregated = aggregateByDate(rawData, _selectedFilter);
    final stats = calculateStatistics(aggregated);
    final streak = _calculateStreak(aggregated);
    final currentYear = DateTime.now().year;

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(isDark, stats, streak, currentYear),
        _buildAnalysisTab(isDark, currentYear, stats, streak),
        _buildActivityTab(isDark, aggregated, streak, currentYear),
      ],
    );
  }

  Widget _buildOverviewTab(
    bool isDark,
    Map<String, dynamic> stats,
    int streak,
    int currentYear,
  ) {
    final monthlyDataForChart = _monthlyBookCount.map(
      (month, count) =>
          MapEntry('$currentYear-${month.toString().padLeft(2, '0')}', count),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnualGoalCard(
            targetBooks: _goalProgress['targetBooks'] as int? ?? 0,
            completedBooks: _goalProgress['completedBooks'] as int? ?? 0,
            year: currentYear,
            onSetGoal: () => _showGoalSheet(context),
          ),
          const SizedBox(height: 16),
          MonthlyBooksChart(
            monthlyData: monthlyDataForChart,
            year: currentYear,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(
    bool isDark,
    int currentYear,
    Map<String, dynamic> stats,
    int streak,
  ) {
    final genreMessage = _progressService.getTopGenreMessage(
      _genreDistribution,
    );

    final sections = [
      'AI 인사이트',
      '완독률',
      '기록/하이라이트',
      '장르 분석',
      '독서 통계',
    ];

    return CustomScrollView(
      controller: _analysisScrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionTabBarDelegate(
            sections: sections,
            isDark: isDark,
            selectedIndex: _selectedSectionIndex,
            onTap: _scrollToSection,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Insight Card
                Container(
                  key: _sectionKeys[0],
                  child: Consumer<ReadingInsightsViewModel>(
                    builder: (context, viewModel, _) {
                      return AiInsightCard(
                        isLoading: viewModel.isLoading,
                        insights: viewModel.insights,
                        error: viewModel.error,
                        canGenerate: viewModel.canGenerate,
                        bookCount: viewModel.bookCount,
                        onGenerate: viewModel.generateInsight,
                        onRetry: viewModel.generateInsight,
                        onClearMemory: viewModel.clearMemory,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Completion Rate Card
                Container(
                  key: _sectionKeys[1],
                  child: CompletionRateCard(
                    totalStarted: _totalStarted,
                    completed: _completedBooks,
                    abandoned: _abandonedBooks,
                    inProgress: _inProgressBooks,
                    completionRate: _completionRate,
                    abandonRate: _abandonRate,
                    retrySuccessRate: _retrySuccessRate,
                  ),
                ),
                const SizedBox(height: 16),

                // Highlight Stats Card
                Container(
                  key: _sectionKeys[2],
                  child: HighlightStatsCard(
                    totalHighlights: _totalHighlights,
                    totalNotes: _totalNotes,
                    totalPhotos: _totalPhotos,
                    genreDistribution: _highlightGenreDistribution,
                    topKeywords: _topKeywords,
                    onHighlightsTap: () => _navigateToMemorablePages(context),
                    onNotesTap: () => _navigateToMemorablePages(context),
                    onPhotosTap: () => _navigateToMemorablePages(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Genre Analysis Card
                Container(
                  key: _sectionKeys[3],
                  child: GenreAnalysisCard(
                    genreDistribution: _genreDistribution,
                    topGenreMessage: genreMessage,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  key: _sectionKeys[4],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '독서 통계',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildStatCard(
                            '총 읽은 페이지',
                            '${stats['total_pages']}p',
                            Icons.menu_book_rounded,
                            AppColors.primary,
                            isDark,
                          ),
                          _buildStatCard(
                            '일평균',
                            '${(stats['average_daily'] as double).toStringAsFixed(1)}p',
                            Icons.calendar_today_rounded,
                            AppColors.success,
                            isDark,
                          ),
                          _buildStatCard(
                            '최고 기록',
                            '${stats['max_daily']}p',
                            Icons.trending_up_rounded,
                            AppColors.warningAlt,
                            isDark,
                          ),
                          _buildStatCard(
                            '연속 독서',
                            '$streak일',
                            Icons.local_fire_department_rounded,
                            AppColors.destructive,
                            isDark,
                          ),
                          _buildStatCard(
                            '최저 기록',
                            '${stats['min_daily']}p',
                            Icons.trending_down_rounded,
                            AppColors.info,
                            isDark,
                          ),
                          FutureBuilder<double>(
                            future: _calculateGoalRate(),
                            builder: (context, snapshot) {
                              final goalRate = snapshot.data ?? 0.0;
                              return _buildStatCard(
                                '오늘 목표',
                                '${(goalRate * 100).toStringAsFixed(0)}%',
                                Icons.flag_rounded,
                                AppColors.info,
                                isDark,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab(
    bool isDark,
    List<Map<String, dynamic>> aggregated,
    int streak,
    int currentYear,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReadingStreakHeatmap(
            dailyPages: _heatmapData,
            year: currentYear,
            currentStreak: streak,
          ),
          const SizedBox(height: 24),
          _buildReadingProgressChart(isDark, aggregated),
          const SizedBox(height: 24),
          Text(
            '일별 읽은 페이지',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (aggregated.isEmpty)
            _buildEmptyListState(isDark)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aggregated.length > 10 ? 10 : aggregated.length,
              itemBuilder: (context, index) {
                final reversedIndex = aggregated.length - 1 - index;
                final item = aggregated[reversedIndex];
                final date = item['date'] as DateTime;
                final dailyPage = item['daily_page'] as int;
                final cumulativePage = item['cumulative_page'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.year}년 ${date.month}월 ${date.day}일',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '누적: $cumulativePage 페이지',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: dailyPage > 0
                                    ? AppColors.success
                                    : Colors.grey,
                              ),
                              Text(
                                '$dailyPage',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: dailyPage > 0
                                      ? AppColors.success
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '페이지',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReadingProgressChart(
    bool isDark,
    List<Map<String, dynamic>> aggregated,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '독서 진행 차트',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Row(
                children: TimeFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getFilterLabel(filter),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '일별 페이지',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '누적 페이지',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (aggregated.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      '아직 데이터가 없어요',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCombinationChartContent(isDark, aggregated),
        ],
      ),
    );
  }

  Widget _buildEmptyListState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.list_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '읽은 기록이 없어요',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationChartContent(
    bool isDark,
    List<Map<String, dynamic>> aggregated,
  ) {
    final maxDaily = aggregated
        .map((e) => e['daily_page'] as int)
        .reduce((a, b) => a > b ? a : b);
    final maxCumulative = aggregated.last['cumulative_page'] as int;

    final barGroups = aggregated.asMap().entries.map((entry) {
      final idx = entry.key;
      final dailyPage = entry.value['daily_page'] as int;
      final normalizedDaily = maxCumulative > 0
          ? (dailyPage / maxDaily) * maxCumulative * 0.3
          : 0.0;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: normalizedDaily,
            color: AppColors.success.withValues(alpha: 0.7),
            width: aggregated.length > 30 ? 4 : 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();

    final lineSpots = aggregated.asMap().entries.map((entry) {
      final idx = entry.key;
      final cumulativePage = entry.value['cumulative_page'] as int;
      return FlSpot(idx.toDouble(), cumulativePage.toDouble());
    }).toList();

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= aggregated.length) {
                        return const SizedBox();
                      }
                      final date = aggregated[idx]['date'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatDate(date, _selectedFilter),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      );
                    },
                    interval: (aggregated.length / 5).ceilToDouble().clamp(
                          1,
                          999,
                        ),
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                  left: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              maxY: maxCumulative.toDouble() * 1.1,
              minY: 0,
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50, bottom: 32),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: lineSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: aggregated.length <= 30,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                maxY: maxCumulative.toDouble() * 1.1,
                minY: 0,
                minX: 0,
                maxX: (aggregated.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx >= 0 && idx < aggregated.length) {
                          final dailyPage =
                              aggregated[idx]['daily_page'] as int;
                          final cumulativePage =
                              aggregated[idx]['cumulative_page'] as int;
                          return LineTooltipItem(
                            '일별: ${dailyPage}p\n누적: ${cumulativePage}p',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> sections;
  final bool isDark;
  final int selectedIndex;
  final Function(int) onTap;

  _SectionTabBarDelegate({
    required this.sections,
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: sections.asMap().entries.map((entry) {
              final index = entry.key;
              final section = entry.value;
              final isSelected = index == selectedIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: !isSelected
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      section,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(_SectionTabBarDelegate oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
