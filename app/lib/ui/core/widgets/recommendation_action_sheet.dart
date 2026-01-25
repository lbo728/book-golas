import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// AI 추천 도서 선택 시 표시되는 액션 바텀시트
/// - 책 내용 상세보기: 서점에서 책 정보 확인
/// - 독서 시작: 해당 책으로 독서 시작
void showRecommendationActionSheet({
  required BuildContext context,
  required String title,
  required String author,
  required VoidCallback onViewDetail,
  required VoidCallback onStartReading,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ActionButton(
                    isDark: isDark,
                    icon: CupertinoIcons.book,
                    label: '책 내용 상세보기',
                    subtitle: '서점에서 책 정보 확인',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onViewDetail();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    isDark: isDark,
                    icon: CupertinoIcons.play_fill,
                    label: '독서 시작',
                    subtitle: '이 책으로 독서를 시작합니다',
                    isPrimary: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onStartReading();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF5B7FFF)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.grey[700]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPrimary
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrimary
                          ? Colors.white70
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isPrimary
                  ? Colors.white70
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
