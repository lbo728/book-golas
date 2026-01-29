import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:book_golas/l10n/app_localizations.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

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
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
                                : AppColors.subtleBlueLight,
                            progressColor: AppColors.primary,
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
                        ? AppColors.errorAlt
                        : AppColors.primary,
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
                _buildDailyTargetButton(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTargetButton(BuildContext context, bool isDark) {
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
              color: AppColors.success.withValues(alpha: 0.1),
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
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.pencil,
                  size: 13,
                  color: AppColors.success,
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
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 12,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.bookDetailGoalAchieved,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
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
