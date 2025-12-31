import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:collection';
import 'package:book_golas/data/services/reading_progress_service.dart';

enum TimeFilter { daily, weekly, monthly }

class ReadingChartScreen extends StatefulWidget {
  const ReadingChartScreen({super.key});

  @override
  State<ReadingChartScreen> createState() => _ReadingChartScreenState();
}

class _ReadingChartScreenState extends State<ReadingChartScreen> {
  TimeFilter _selectedFilter = TimeFilter.daily;
  bool _useMockData = false;
  final ReadingProgressService _progressService = ReadingProgressService();

  // 캐싱된 데이터
  List<Map<String, dynamic>>? _cachedRawData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await fetchUserProgressHistory();
      if (mounted) {
        setState(() {
          _cachedRawData = data;
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

  /// Mock 데이터 생성 (데모용)
  List<Map<String, dynamic>> _generateMockData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> mockData = [];

    // 지난 30일간의 랜덤 독서 기록 생성
    for (int i = 30; i > 0; i--) {
      final date = now.subtract(Duration(days: i));

      // 하루에 1-3번 독서 기록
      final sessionsCount = (i % 3) + 1;
      for (int j = 0; j < sessionsCount; j++) {
        final basePages = 20 + (i % 50); // 20-70 페이지
        final randomPages = basePages + (j * 15);

        mockData.add({
          'page': randomPages,
          'book_id': 'mock-book-${i % 3}', // 3권의 책을 번갈아가며
          'created_at': date.add(Duration(hours: 8 + (j * 4))),
        });
      }
    }

    return mockData;
  }

  Future<List<Map<String, dynamic>>> fetchUserProgressHistory() async {
    // Mock 데이터 모드일 경우 Mock 데이터 반환
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500)); // 로딩 시뮬레이션
      return _generateMockData();
    }

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
          final diff = weekday - 1; // Monday = 0
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

      // 같은 날짜에 같은 책의 최대 페이지만 저장
      if (bookId != null) {
        dateData[key]![bookId] =
            (dateData[key]![bookId] ?? 0) < page ? page : dateData[key]![bookId]!;
      }
    }

    // 누적 페이지 계산
    int cumulativePages = 0;
    final result = <Map<String, dynamic>>[];

    for (final entry in dateData.entries) {
      final dailyTotal = entry.value.values.fold<int>(0, (sum, page) => sum + page);
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

  /// 연속 독서일(스트릭) 계산
  int _calculateStreak(List<Map<String, dynamic>> aggregatedData) {
    if (aggregatedData.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // 날짜별로 정렬 (최신순)
    final sortedDates = aggregatedData
        .map((e) => e['date'] as DateTime)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    DateTime expectedDate = todayNormalized;

    // 오늘 기록이 없으면 어제부터 시작
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
        // 날짜가 건너뛰어졌으면 스트릭 종료
        break;
      }
    }

    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 목표 달성률 계산 (오늘 기준)
  Future<double> _calculateGoalRate() async {
    return await _progressService.calculateGoalAchievementRate();
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
        actions: [
          // Mock 데이터 토글 버튼
          Tooltip(
            message: _useMockData ? 'Mock 데이터 끄기' : 'Mock 데이터 보기',
            child: IconButton(
              icon: Icon(
                _useMockData ? Icons.visibility_off : Icons.visibility,
                color: _useMockData ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _useMockData = !_useMockData;
                });
                // 목업 데이터 토글 시 데이터 다시 로드
                _loadData();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    // 로딩 중
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러 발생
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
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

    // 데이터 없음
    final rawData = _cachedRawData ?? [];
    if (rawData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                '아직 독서 기록이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '책을 읽고 페이지를 업데이트해보세요!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 캐시된 데이터로 필터링 및 통계 계산 (필터 변경 시 즉시 반영)
    final aggregated = aggregateByDate(rawData, _selectedFilter);
    final stats = calculateStatistics(aggregated);
    final streak = _calculateStreak(aggregated);

    final spots = aggregated.asMap().entries.map((entry) {
      final idx = entry.key;
      final cumulativePage = entry.value['cumulative_page'] as int;
      return FlSpot(idx.toDouble(), cumulativePage.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    // 통계 카드 (2x3 그리드)
                    GridView.count(
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

                    const SizedBox(height: 24),

                    // 필터 버튼
                    Row(
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
                                  backgroundColor: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
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

                    const SizedBox(height: 24),

                    // 차트
                    Text(
                      '누적 페이지 차트',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
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

                    // 일별 증감 리스트
                    Text(
                      '일별 읽은 페이지',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                        color: dailyPage > 0 ? Colors.green : Colors.grey,
                                      ),
                                      Text(
                                        '$dailyPage',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: dailyPage > 0 ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '페이지',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
