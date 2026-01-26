import 'package:flutter/material.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

/// 독서 스트릭 히트맵
///
/// GitHub 스타일의 히트맵으로 일별 독서량을 시각화
class ReadingStreakHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyPages;
  final int year;
  final int currentStreak;

  const ReadingStreakHeatmap({
    super.key,
    required this.dailyPages,
    required this.year,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentYear = year == now.year;

    final totalDays = dailyPages.values.where((v) => v > 0).length;
    final totalPages = dailyPages.values.fold(0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 24,
                        color: AppColors.destructive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$year년 독서 히트맵',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isCurrentYear && currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak일',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.destructive,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: '독서한 날',
                  value: '$totalDays일',
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                _buildStatItem(
                  label: '총 페이지',
                  value: _formatNumber(totalPages),
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                _buildStatItem(
                  label: '일평균',
                  value: totalDays > 0
                      ? '${(totalPages / totalDays).round()}p'
                      : '0p',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHeatmapGrid(isDark),
            const SizedBox(height: 12),
            _buildLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid(bool isDark) {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    final now = DateTime.now();

    final startOffset = firstDay.weekday % 7;
    final totalWeeks =
        ((lastDay.difference(firstDay).inDays + startOffset) / 7).ceil() + 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map(
                  (day) => SizedBox(
                    width: 14,
                    height: 14,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 8,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 7 * 14.0 + 6 * 2.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(totalWeeks, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final daysFromStart =
                          weekIndex * 7 + dayIndex - startOffset;
                      final date = firstDay.add(Duration(days: daysFromStart));

                      if (date.year != year) {
                        return _buildEmptyCell();
                      }

                      if (year == now.year && date.isAfter(now)) {
                        return _buildEmptyCell();
                      }

                      final dateKey = DateTime(date.year, date.month, date.day);
                      final pages = dailyPages[dateKey] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: '${date.month}/${date.day}: $pages페이지',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getColorForPages(pages, isDark),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _getMonthLabels()
                .map(
                  (month) => SizedBox(
                    width: month.isEmpty ? 28 : 42,
                    child: Text(
                      month,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(width: 12, height: 12),
    );
  }

  List<String> _getMonthLabels() {
    return ['1월', '', '3월', '', '5월', '', '7월', '', '9월', '', '11월', ''];
  }

  Color _getColorForPages(int pages, bool isDark) {
    if (pages == 0) {
      return isDark ? Colors.grey[850]! : Colors.grey[200]!;
    }
    if (pages <= 10) {
      return AppColors.info.withOpacity(0.3);
    }
    if (pages <= 30) {
      return AppColors.info.withOpacity(0.5);
    }
    if (pages <= 50) {
      return AppColors.info.withOpacity(0.7);
    }
    return AppColors.info;
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '적음',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        _buildLegendBox(_getColorForPages(0, isDark)),
        _buildLegendBox(_getColorForPages(5, isDark)),
        _buildLegendBox(_getColorForPages(20, isDark)),
        _buildLegendBox(_getColorForPages(40, isDark)),
        _buildLegendBox(_getColorForPages(60, isDark)),
        const SizedBox(width: 4),
        Text(
          '많음',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
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

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}만';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}
