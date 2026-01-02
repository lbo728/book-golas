import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/book.dart';

class DetailTab extends StatelessWidget {
  final Book book;
  final int attemptCount;
  final String attemptEncouragement;
  final Map<String, bool> dailyAchievements;
  final VoidCallback onTargetDateChange;

  const DetailTab({
    super.key,
    required this.book,
    required this.attemptCount,
    required this.attemptEncouragement,
    required this.dailyAchievements,
    required this.onTargetDateChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingScheduleCard(isDark),
          const SizedBox(height: 16),
          _buildTodayGoalCardWithStamps(isDark),
        ],
      ),
    );
  }

  Widget _buildReadingScheduleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B7FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: Color(0xFF5B7FFF),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '독서 일정',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleRow(
            '시작일',
            book.startDate.toString().substring(0, 10).replaceAll('-', '.'),
            CupertinoIcons.play_circle,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.flag_fill,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '목표일',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      book.targetDate
                          .toString()
                          .substring(0, 10)
                          .replaceAll('-', '.'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (attemptCount > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$attemptCount번째 · $attemptEncouragement',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onTargetDateChange,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value, IconData icon,
      {Widget? trailing, bool isDark = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildTodayGoalCardWithStamps(bool isDark) {
    final totalDays = book.targetDate.difference(book.startDate).inDays + 1;
    final now = DateTime.now();
    final todayIndex = now.difference(book.startDate).inDays;

    int achievedCount = 0;
    int passedDays = 0;
    for (int i = 0; i < totalDays && i <= todayIndex; i++) {
      final date = book.startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (dailyAchievements[dateKey] == true) achievedCount++;
      passedDays++;
    }
    final achievementRate =
        passedDays > 0 ? (achievedCount / passedDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalHeader(passedDays, achievedCount, achievementRate, isDark),
          const SizedBox(height: 20),
          _buildStampGrid(totalDays, now, isDark),
          const SizedBox(height: 16),
          _buildLegendRow(isDark),
        ],
      ),
    );
  }

  Widget _buildGoalHeader(
      int passedDays, int achievedCount, int achievementRate, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.flame_fill,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '목표 달성 현황',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$passedDays일 중 $achievedCount일 달성',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
        _buildAchievementBadge(achievementRate),
      ],
    );
  }

  Widget _buildAchievementBadge(int achievementRate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: achievementRate >= 80
            ? const Color(0xFFD1FAE5)
            : achievementRate >= 50
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievementRate >= 80
                ? CupertinoIcons.star_fill
                : achievementRate >= 50
                    ? CupertinoIcons.hand_thumbsup_fill
                    : CupertinoIcons.flame_fill,
            size: 14,
            color: achievementRate >= 80
                ? const Color(0xFF059669)
                : achievementRate >= 50
                    ? const Color(0xFFD97706)
                    : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            '$achievementRate%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: achievementRate >= 80
                  ? const Color(0xFF059669)
                  : achievementRate >= 50
                      ? const Color(0xFFD97706)
                      : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampGrid(int totalDays, DateTime now, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cellSize = 28.0;
        const spacing = 4.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(totalDays, (index) {
            final date = book.startDate.add(Duration(days: index));
            final dateKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final isFuture =
                date.isAfter(DateTime(now.year, now.month, now.day));
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isAchieved = dailyAchievements[dateKey];

            Color cellColor;
            if (isFuture) {
              cellColor = isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF3F4F6);
            } else if (isAchieved == true) {
              cellColor = const Color(0xFF10B981);
            } else if (isAchieved == false) {
              cellColor = const Color(0xFFFCA5A5);
            } else {
              cellColor = isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB);
            }

            return Tooltip(
              message:
                  '${date.month}/${date.day} (Day ${index + 1})${isAchieved == true ? ' ✓' : isAchieved == false ? ' ✗' : ''}',
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(
                          color: const Color(0xFF5B7FFF),
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: isToday
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B7FFF),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLegendRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('달성', const Color(0xFF10B981), isDark),
        const SizedBox(width: 16),
        _buildLegendItem('미달성', const Color(0xFFFCA5A5), isDark),
        const SizedBox(width: 16),
        _buildLegendItem(
            '예정',
            isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            isDark),
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
}
