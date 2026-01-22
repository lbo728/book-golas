import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 월별 독서량 바 차트
///
/// 올해 월별로 완독한 책 수를 바 차트로 시각화
class MonthlyBooksChart extends StatelessWidget {
  final Map<String, int> monthlyData;
  final int year;

  const MonthlyBooksChart({
    super.key,
    required this.monthlyData,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMonth = now.year == year ? now.month : 12;

    final thisMonthKey = '$year-${currentMonth.toString().padLeft(2, '0')}';
    final lastMonthKey = currentMonth > 1
        ? '$year-${(currentMonth - 1).toString().padLeft(2, '0')}'
        : '${year - 1}-12';

    final thisMonth = monthlyData[thisMonthKey] ?? 0;
    final lastMonth = monthlyData[lastMonthKey] ?? 0;
    final diff = thisMonth - lastMonth;
    final diffPercent = lastMonth > 0
        ? ((diff / lastMonth) * 100).round()
        : (thisMonth > 0 ? 100 : 0);

    final maxY = monthlyData.values.isEmpty
        ? 5.0
        : (monthlyData.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 24,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$year년 월별 독서량',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  label: '이번 달',
                  value: '$thisMonth권',
                  isDark: isDark,
                ),
                _buildStatColumn(
                  label: '지난 달',
                  value: '$lastMonth권',
                  isDark: isDark,
                ),
                _buildStatColumn(
                  label: '증감',
                  value: diff >= 0 ? '+$diffPercent%' : '$diffPercent%',
                  isDark: isDark,
                  valueColor:
                      diff > 0 ? Colors.green : (diff < 0 ? Colors.red : null),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor:
                          isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${groupIndex + 1}월\n${rod.toY.toInt()}권',
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final month = value.toInt() + 1;
                          final isCurrentMonth = month == currentMonth;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '$month',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentMonth
                                    ? const Color(0xFF5B7FFF)
                                    : (isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600]),
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 10 ? 5 : 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: _generateBarGroups(currentMonth, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(int currentMonth, bool isDark) {
    return List.generate(12, (index) {
      final month = index + 1;
      final key = '$year-${month.toString().padLeft(2, '0')}';
      final count = monthlyData[key] ?? 0;
      final isCurrentMonth = month == currentMonth;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: isCurrentMonth
                ? const Color(0xFF5B7FFF)
                : (isDark
                    ? const Color(0xFF4ECDC4).withOpacity(0.7)
                    : const Color(0xFF4ECDC4)),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              color: isDark ? Colors.grey[850] : Colors.grey[100],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
