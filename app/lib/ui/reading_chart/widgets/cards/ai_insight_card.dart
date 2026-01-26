import 'package:flutter/material.dart';
import 'package:book_golas/domain/models/reading_insight.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

/// AI 인사이트 카드
///
/// 독서 패턴을 분석하여 AI가 생성한 인사이트를 표시
class AiInsightCard extends StatelessWidget {
  final bool isLoading;
  final List<ReadingInsight>? insights;
  final String? error;
  final bool canGenerate;
  final int bookCount;
  final VoidCallback onGenerate;
  final VoidCallback? onRetry;

  const AiInsightCard({
    super.key,
    required this.isLoading,
    this.insights,
    this.error,
    required this.canGenerate,
    required this.bookCount,
    required this.onGenerate,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            _buildHeader(context, isDark),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState(context, isDark)
            else if (error != null)
              _buildErrorState(context, isDark)
            else if (bookCount < 3)
              _buildDisabledState(context, isDark)
            else if (insights != null && insights!.isNotEmpty)
              _buildSuccessState(context, isDark)
            else
              _buildEmptyState(context, isDark),
            const SizedBox(height: 16),
            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'AI 인사이트',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '독서 패턴을 분석하고 있어요...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? Colors.red[300] : Colors.red[700],
          ),
          const SizedBox(height: 12),
          Text(
            error ?? '알 수 없는 오류가 발생했습니다',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDisabledState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 인사이트를 받으려면 책을 더 읽어보세요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 완독한 책: $bookCount권',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '최소 3권, 권장 5권 이상',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights!.map((insight) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getCategoryIcon(insight.category, isDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (insight.relatedBooks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: insight.relatedBooks.map((book) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          book,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '아래 버튼을 눌러 인사이트를 생성해보세요',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    if (canGenerate && bookCount >= 3) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '분석하기',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (bookCount >= 3) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '오늘 이미 분석했어요. 내일 다시 시도해주세요.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Icon _getCategoryIcon(String category, bool isDark) {
    final color =
        isDark ? AppColors.primary.withOpacity(0.8) : AppColors.primary;

    switch (category) {
      case 'pattern':
        return Icon(Icons.trending_up, size: 20, color: color);
      case 'milestone':
        return Icon(Icons.emoji_events, size: 20, color: color);
      case 'reflection':
        return Icon(Icons.lightbulb_outline, size: 20, color: color);
      default:
        return Icon(Icons.info_outline, size: 20, color: color);
    }
  }
}
