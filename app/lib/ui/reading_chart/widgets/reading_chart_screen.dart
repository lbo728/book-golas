import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:collection';
import 'package:book_golas/data/services/reading_progress_service.dart';
import 'package:book_golas/data/services/reading_goal_service.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/genre_analysis_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/monthly_books_chart.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/annual_goal_card.dart';
import 'package:book_golas/ui/reading_chart/widgets/cards/reading_streak_heatmap.dart';
import 'package:book_golas/ui/reading_chart/widgets/sheets/reading_goal_sheet.dart';

enum TimeFilter { daily, weekly, monthly }

class ReadingChartScreen extends StatefulWidget {
  const ReadingChartScreen({super.key});

  @override
  State<ReadingChartScreen> createState() => _ReadingChartScreenState();
}

class _ReadingChartScreenState extends State<ReadingChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeFilter _selectedFilter = TimeFilter.daily;
  final ReadingProgressService _progressService = ReadingProgressService();
  final ReadingGoalService _goalService = ReadingGoalService();

  List<Map<String, dynamic>>? _cachedRawData;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, int> _genreDistribution = {};
  Map<int, int> _monthlyBookCount = {};
  Map<String, dynamic> _goalProgress = {};
  Map<DateTime, int> _heatmapData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<List<Map<String, dynamic>>> fetchUserProgressHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('reading_progress_history')
        .select('page, book_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => {
              'page': e['page'] as int,
              'book_id': e['book_id'] as String?,
              'created_at': DateTime.parse(e['created_at'] as String),
            })
        .toList();
  }

  List<Map<String, dynamic>> aggregateByDate(
      List<Map<String, dynamic>> data, TimeFilter filter) {
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
          key = DateTime(createdAt.year, createdAt.month, createdAt.day)
              .subtract(Duration(days: diff));
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
      final dailyTotal =
          entry.value.values.fold<int>(0, (sum, page) => sum + page);
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
      await _goalService.setYearlyGoal(
        year: currentYear,
        targetBooks: result,
      );
      _loadData();
    }
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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        title: const Text('나의 독서 상태'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.grey[600] : Colors.grey[400],
          indicatorColor: const Color(0xFF5B7FFF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '개요'),
            Tab(text: '분석'),
            Tab(text: '활동'),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildContent(isDark),
      ),
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
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '데이터를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('다시 시도'),
              ),
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
        _buildAnalysisTab(isDark, currentYear),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '독서 통계',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  '총 읽은 페이지',
                  '${stats['total_pages']}p',
                  Icons.menu_book_rounded,
                  const Color(0xFF5B7FFF),
                  isDark,
                ),
                _buildStatCard(
                  '일평균',
                  '${(stats['average_daily'] as double).toStringAsFixed(1)}p',
                  Icons.calendar_today_rounded,
                  const Color(0xFF10B981),
                  isDark,
                ),
                _buildStatCard(
                  '최고 기록',
                  '${stats['max_daily']}p',
                  Icons.trending_up_rounded,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
                _buildStatCard(
                  '연속 독서',
                  '$streak일',
                  Icons.local_fire_department_rounded,
                  const Color(0xFFEF4444),
                  isDark,
                ),
                _buildStatCard(
                  '최저 기록',
                  '${stats['min_daily']}p',
                  Icons.trending_down_rounded,
                  const Color(0xFF8B5CF6),
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
                      const Color(0xFF06B6D4),
                      isDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(bool isDark, int currentYear) {
    final genreMessage =
        _progressService.getTopGenreMessage(_genreDistribution);

    final monthlyDataForChart = _monthlyBookCount.map(
      (month, count) => MapEntry(
        '$currentYear-${month.toString().padLeft(2, '0')}',
        count,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenreAnalysisCard(
            genreDistribution: _genreDistribution,
            topGenreMessage: genreMessage,
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

  Widget _buildActivityTab(
    bool isDark,
    List<Map<String, dynamic>> aggregated,
    int streak,
    int currentYear,
  ) {
    final spots = aggregated.asMap().entries.map((entry) {
      final idx = entry.key;
      final cumulativePage = entry.value['cumulative_page'] as int;
      return FlSpot(idx.toDouble(), cumulativePage.toDouble());
    }).toList();

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '기간 선택',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: TimeFilter.values.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            }
                          },
                          selectedColor: Colors.blue,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '누적 페이지 차트',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (aggregated.isEmpty)
            _buildEmptyChartState(isDark)
          else
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
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
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
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
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          );
                        },
                        interval: (aggregated.length / 5)
                            .ceilToDouble()
                            .clamp(1, 999),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: null,
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
                  minY: 0,
                ),
              ),
            ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '일별 읽은 페이지',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (aggregated.isEmpty)
            _buildEmptyListState(isDark)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
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
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                Text(
                                  '$dailyPage',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: dailyPage > 0
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '페이지',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '아직 데이터가 없어요',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.list_alt,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '읽은 기록이 없어요',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
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
