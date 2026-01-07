import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'circular_progress_painter.dart';

class DashboardProgressWidget extends StatelessWidget {
  final double animatedProgress;
  final int currentPage;
  final int totalPages;
  final int daysLeft;
  final int pagesLeft;
  final int? dailyTargetPages;
  final bool isTodayGoalAchieved;
  final VoidCallback onDailyTargetTap;

  const DashboardProgressWidget({
    super.key,
    required this.animatedProgress,
    required this.currentPage,
    required this.totalPages,
    required this.daysLeft,
    required this.pagesLeft,
    required this.dailyTargetPages,
    this.isTodayGoalAchieved = false,
    required this.onDailyTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressPercent = (animatedProgress * 100).toStringAsFixed(0);
    final isOverdue = daysLeft < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: CircularProgressPainter(
                            progress: animatedProgress.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFEEF2FF),
                            progressColor: const Color(0xFF5B7FFF),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$currentPage / ${totalPages}p',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 100,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isOverdue ? 'D+${daysLeft.abs()}' : 'D-$daysLeft',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isOverdue || daysLeft <= 3
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF5B7FFF),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$pagesLeft페이지',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      TextSpan(
                        text: ' 남았어요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildDailyTargetButton(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTargetButton(bool isDark) {
    final dailyTarget = dailyTargetPages ??
        (daysLeft > 0 ? (pagesLeft / daysLeft).ceil() : pagesLeft);
    if (dailyTarget <= 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDailyTargetTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '오늘 목표: ${dailyTarget}p',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.pencil,
                  size: 13,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
        if (isTodayGoalAchieved) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 12,
                  color: Color(0xFFD4A000),
                ),
                SizedBox(width: 4),
                Text(
                  '목표 달성',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4A000),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
