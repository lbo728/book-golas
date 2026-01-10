import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookListSkeleton extends StatelessWidget {
  final int itemCount;

  const BookListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
      itemCount: itemCount,
      itemBuilder: (context, index) => _BookListSkeletonCard(
        isDark: isDark,
        index: index,
      ),
    );
  }
}

class _BookListSkeletonCard extends StatelessWidget {
  final bool isDark;
  final int index;

  const _BookListSkeletonCard({
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidths = [double.infinity, 180.0, 220.0];
    final subtitleWidths = [140.0, 100.0, 160.0];

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCoverSkeleton(),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoSkeleton(titleWidths, subtitleWidths),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSkeleton() {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
        ),
      ),
    );
  }

  Widget _buildInfoSkeleton(
      List<double> titleWidths, List<double> subtitleWidths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: titleWidths[index % 3],
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              height: 24,
              width: 52,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 14,
              width: subtitleWidths[index % 3],
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 12,
              width: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
