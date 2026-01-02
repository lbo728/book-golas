import 'package:flutter/material.dart';

import 'package:book_golas/core/widgets/book_image_widget.dart';

class CompactBookHeader extends StatelessWidget {
  final String? imageUrl;
  final String bookId;
  final String title;
  final String? author;
  final int currentPage;
  final int totalPages;
  final void Function(String heroTag, String imageUrl) onImageTap;
  final VoidCallback? onTitleTap;

  const CompactBookHeader({
    super.key,
    required this.imageUrl,
    required this.bookId,
    required this.title,
    this.author,
    required this.currentPage,
    required this.totalPages,
    required this.onImageTap,
    this.onTitleTap,
  });

  bool get isCompleted => currentPage >= totalPages && totalPages > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBookCover(isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(isDark),
                const SizedBox(height: 4),
                _buildAuthorAndStatus(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover(bool isDark) {
    final heroTag = 'book_cover_compact_$bookId';

    return GestureDetector(
      onTap: () {
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          onImageTap(heroTag, imageUrl!);
        }
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          width: 60,
          height: 85,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BookImageWidget(
              imageUrl: imageUrl,
              iconSize: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return GestureDetector(
      onTap: title.length > 20 ? onTitleTap : null,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: isDark ? Colors.white : Colors.black,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAuthorAndStatus(bool isDark) {
    return Row(
      children: [
        if (author != null) ...[
          Flexible(
            child: Text(
              author!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            ' · ',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981).withOpacity(0.12)
                : const Color(0xFF5B7FFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isCompleted ? '✓ 완독' : '● 독서 중',
            style: TextStyle(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFF5B7FFF),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
