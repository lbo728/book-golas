import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProgressHistoryTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> progressFuture;
  final int attemptCount;
  final String attemptEncouragement;
  final double progressPercentage;
  final int daysLeft;
  final DateTime startDate;
  final DateTime targetDate;

  const ProgressHistoryTab({
    super.key,
    required this.progressFuture,
    required this.attemptCount,
    required this.attemptEncouragement,
    required this.progressPercentage,
    required this.daysLeft,
    required this.startDate,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: progressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(isDark);
        }

        final rawData = snapshot.data ?? [];

        if (rawData.isEmpty) {
          return _buildEmptyState(isDark);
        }

        final aggregatedData = _aggregateByDate(rawData);
        return _buildContent(aggregatedData, isDark);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '진행률 기록이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> data, bool isDark) {
    final spots = data.asMap().entries.map((entry) {
      final idx = entry.key;
      final page = entry.value['page'] as int;
      return FlSpot(idx.toDouble(), page.toDouble());
    }).toList();

    final maxPage = data.isNotEmpty
        ? (data.map((e) => e['page'] as int).reduce((a, b) => a > b ? a : b))
            .toDouble()
        : 100.0;

    final dailyPagesSpots = data.asMap().entries.map((entry) {
      final idx = entry.key;
      final page = entry.value['page'] as int;
      final prevPage = idx > 0 ? data[idx - 1]['page'] as int : 0;
      final dailyPages = (page - prevPage).toDouble();
      return FlSpot(idx.toDouble(), dailyPages);
    }).toList();

    final maxDailyPage = dailyPagesSpots.isNotEmpty
        ? dailyPagesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 50.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartCard(
              data, spots, maxPage, dailyPagesSpots, maxDailyPage, isDark),
          const SizedBox(height: 16),
          _buildReadingStateAnalysis(isDark, data),
          const SizedBox(height: 16),
          _buildDailyRecords(data, isDark),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    List<Map<String, dynamic>> data,
    List<FlSpot> spots,
    double maxPage,
    List<FlSpot> dailyPagesSpots,
    double maxDailyPage,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(data.length, isDark),
          const SizedBox(height: 16),
          _buildLegendRow(isDark),
          const SizedBox(height: 20),
          _buildChart(
              data, spots, maxPage, dailyPagesSpots, maxDailyPage, isDark),
        ],
      ),
    );
  }

  Widget _buildChartHeader(int recordCount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '📈 누적 페이지',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (attemptCount > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$attemptCount번째 · $attemptEncouragement',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5B7FFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$recordCount일 기록',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B7FFF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('누적 페이지', const Color(0xFF5B7FFF), isDark),
        const SizedBox(width: 24),
        _buildLegendItem('일일 페이지', const Color(0xFF10B981), isDark),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    List<Map<String, dynamic>> data,
    List<FlSpot> spots,
    double maxPage,
    List<FlSpot> dailyPagesSpots,
    double maxDailyPage,
    bool isDark,
  ) {
    return SizedBox(
      height: 250,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth - 40;
          final barWidth = data.length > 1
              ? (chartWidth / data.length * 0.4).clamp(4.0, 16.0)
              : 16.0;

          final scaledMaxY = (maxPage * 1.1).ceilToDouble();
          final barScaleFactor =
              scaledMaxY / (maxDailyPage > 0 ? maxDailyPage * 1.5 : 1);

          return LineChart(
            LineChartData(
              lineBarsData: [
                ...dailyPagesSpots.map((spot) {
                  final scaledY = spot.y * barScaleFactor * 0.3;
                  return LineChartBarData(
                    spots: [
                      FlSpot(spot.x, 0),
                      FlSpot(spot.x, scaledY.clamp(0, scaledMaxY * 0.35)),
                    ],
                    isCurved: false,
                    color: const Color(0xFF10B981),
                    barWidth: barWidth,
                    dotData: const FlDotData(show: false),
                  );
                }),
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B7FFF), Color(0xFF4A6FE8)],
                  ),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF5B7FFF),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5B7FFF).withValues(alpha: 0.15),
                        const Color(0xFF5B7FFF).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
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
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox();
                      }
                      final date = data[idx]['created_at'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.month}/${date.day}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      );
                    },
                    interval:
                        data.length > 5 ? (data.length / 4).ceilToDouble() : 1,
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
                  ),
                  left: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
              ),
              minX: -0.5,
              maxX: data.length - 0.5,
              minY: 0,
              maxY: scaledMaxY,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingStateAnalysis(
      bool isDark, List<Map<String, dynamic>> progressData) {
    final analysisResult = _analyzeReadingState(progressData);
    final emoji = analysisResult['emoji'] as String;
    final title = analysisResult['title'] as String;
    final message = analysisResult['message'] as String;
    final color = analysisResult['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (attemptCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$attemptCount번째 · $attemptEncouragement',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analyzeReadingState(
      List<Map<String, dynamic>> progressData) {
    final totalDays = targetDate.difference(startDate).inDays + 1;
    final elapsedDays = DateTime.now().difference(startDate).inDays;

    final expectedProgress =
        elapsedDays > 0 ? (elapsedDays / totalDays * 100).clamp(0, 100) : 0.0;
    final progressDiff = progressPercentage - expectedProgress;

    if (progressPercentage >= 100) {
      if (attemptCount > 1) {
        return {
          'emoji': '🏆',
          'title': '드디어 완독!',
          'message': '$attemptCount번의 도전 끝에 완독에 성공했어요. 포기하지 않은 당신이 멋져요!',
          'color': const Color(0xFF10B981),
        };
      }
      return {
        'emoji': '🎉',
        'title': '완독 축하해요!',
        'message': '목표를 달성했어요. 다음 책도 함께 읽어볼까요?',
        'color': const Color(0xFF10B981),
      };
    }

    if (daysLeft < 0) {
      if (attemptCount > 1) {
        return {
          'emoji': '💪',
          'title': '이번엔 완주해봐요',
          'message': '$attemptCount번째 도전이에요. 목표일을 재설정하고 끝까지 읽어볼까요?',
          'color': const Color(0xFFFF6B6B),
        };
      }
      return {
        'emoji': '⏰',
        'title': '목표일이 지났어요',
        'message': '괜찮아요, 새 목표일을 설정하고 다시 시작해봐요!',
        'color': const Color(0xFFFF6B6B),
      };
    }

    if (progressDiff > 20) {
      return {
        'emoji': '🚀',
        'title': '놀라운 속도예요!',
        'message': '예상보다 훨씬 빠르게 읽고 있어요. 이 페이스면 일찍 완독할 수 있겠어요!',
        'color': const Color(0xFF5B7FFF),
      };
    }

    if (progressDiff > 5) {
      return {
        'emoji': '✨',
        'title': '순조롭게 진행 중!',
        'message': '계획보다 앞서가고 있어요. 이대로만 하면 목표 달성 확실해요!',
        'color': const Color(0xFF10B981),
      };
    }

    if (progressDiff > -5) {
      return {
        'emoji': '📖',
        'title': '계획대로 진행 중',
        'message': '꾸준히 읽고 있어요. 오늘도 조금씩 읽어볼까요?',
        'color': const Color(0xFF5B7FFF),
      };
    }

    if (progressDiff > -15) {
      if (attemptCount > 1) {
        return {
          'emoji': '🔥',
          'title': '조금 더 속도를 내볼까요?',
          'message': '이번에는 꼭 완독해봐요. 매일 조금씩 더 읽으면 따라잡을 수 있어요!',
          'color': const Color(0xFFF59E0B),
        };
      }
      return {
        'emoji': '📚',
        'title': '조금 더 읽어볼까요?',
        'message': '계획보다 살짝 뒤처졌어요. 오늘 조금 더 읽으면 따라잡을 수 있어요!',
        'color': const Color(0xFFF59E0B),
      };
    }

    if (attemptCount > 1) {
      return {
        'emoji': '💫',
        'title': '포기하지 마세요!',
        'message': '$attemptCount번째 도전 중이에요. 목표일을 조정하거나 더 집중해서 읽어봐요!',
        'color': const Color(0xFFFF6B6B),
      };
    }
    return {
      'emoji': '📅',
      'title': '목표 재설정이 필요할 수도',
      'message': '현재 페이스로는 목표 달성이 어려워요. 목표일을 조정해볼까요?',
      'color': const Color(0xFFFF6B6B),
    };
  }

  Widget _buildDailyRecords(List<Map<String, dynamic>> data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 일별 기록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...data.reversed.take(5).map((record) {
          final date = record['created_at'] as DateTime;
          final page = record['page'] as int;
          final index = data.indexOf(record);
          final prevPage = index > 0 ? data[index - 1]['page'] as int : 0;
          final pagesRead = page - prevPage;

          return _buildDailyRecordItem(date, page, pagesRead, isDark);
        }),
      ],
    );
  }

  Widget _buildDailyRecordItem(
      DateTime date, int page, int pagesRead, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B7FFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '누적: $page 페이지',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$pagesRead',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              Text(
                '페이지',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _aggregateByDate(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final SplayTreeMap<String, Map<String, dynamic>> dateMap = SplayTreeMap();

    for (final entry in data) {
      final createdAt = entry['created_at'] as DateTime;
      final dateKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      final page = entry['page'] as int;

      if (!dateMap.containsKey(dateKey) ||
          (dateMap[dateKey]!['page'] as int) < page) {
        dateMap[dateKey] = {
          'page': page,
          'created_at':
              DateTime(createdAt.year, createdAt.month, createdAt.day),
        };
      }
    }

    return dateMap.values.toList();
  }

  Widget _buildSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
                3,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 60,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
