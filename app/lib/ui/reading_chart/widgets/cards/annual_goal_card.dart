import 'package:flutter/material.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

/// 연간 목표 진행률 카드
///
/// 연간 독서 목표 대비 현재 진행률을 시각화
class AnnualGoalCard extends StatelessWidget {
  final int? targetBooks;
  final int completedBooks;
  final int year;
  final VoidCallback? onSetGoal;
  final VoidCallback? onEditGoal;

  const AnnualGoalCard({
    super.key,
    this.targetBooks,
    required this.completedBooks,
    required this.year,
    this.onSetGoal,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (targetBooks == null || targetBooks == 0) {
      return _buildNoGoalState(context, isDark);
    }

    final progress = (completedBooks / targetBooks!).clamp(0.0, 1.0);
    final remaining = targetBooks! - completedBooks;
    final isAchieved = completedBooks >= targetBooks!;

    final now = DateTime.now();
    final daysElapsed = now.difference(DateTime(year, 1, 1)).inDays + 1;
    final totalDays =
        DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays + 1;
    final expectedBooks = ((daysElapsed / totalDays) * targetBooks!).round();
    final isAhead = completedBooks >= expectedBooks;

    return Container(
      decoration: BoxDecoration(
        gradient: isAchieved
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              )
            : null,
        color: isAchieved
            ? null
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
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
                        color: isAchieved
                            ? Colors.white.withOpacity(0.2)
                            : AppColors.warningAlt.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAchieved
                            ? Icons.emoji_events_rounded
                            : Icons.flag_rounded,
                        size: 24,
                        color: isAchieved ? Colors.white : AppColors.warningAlt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$year년 독서 목표',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAchieved
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
                if (onEditGoal != null)
                  IconButton(
                    onPressed: onEditGoal,
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: isAchieved
                          ? Colors.white70
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completedBooks',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isAchieved
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '/ $targetBooks권',
                    style: TextStyle(
                      fontSize: 20,
                      color: isAchieved
                          ? Colors.white70
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: isAchieved
                    ? Colors.white.withOpacity(0.3)
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved
                      ? Colors.white
                      : (progress >= 0.7
                          ? AppColors.success
                          : (progress >= 0.4
                              ? AppColors.warningAlt
                              : AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% 달성',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isAchieved
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (!isAchieved)
                  Text(
                    '$remaining권 남음',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAchieved
                    ? Colors.white.withOpacity(0.15)
                    : (isDark ? Colors.grey[850] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    isAchieved ? '🎉' : (isAhead ? '🔥' : '💪'),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAchieved
                          ? '축하합니다! 올해 목표를 달성했어요!'
                          : (isAhead
                              ? '예상보다 ${completedBooks - expectedBooks}권 더 읽었어요!'
                              : '조금만 더 힘내면 목표에 도달할 수 있어요!'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isAchieved
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGoalState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$year년 독서 목표를 설정해보세요!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '목표를 설정하면 독서 진행 상황을\n한눈에 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (onSetGoal != null)
            ElevatedButton(
              onPressed: onSetGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '목표 설정하기',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
