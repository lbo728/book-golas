import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:book_golas/core/widgets/custom_snackbar.dart';

void showFullTitleSheet({
  required BuildContext context,
  required String title,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
                    '도서 제목',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: title));
                        Navigator.pop(sheetContext);
                        CustomSnackbar.show(
                          context,
                          message: '제목이 복사되었습니다',
                          type: SnackbarType.success,
                          bottomOffset: 40,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_on_clipboard,
                              size: 18,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '복사하기',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showBookstoreSelectSheet(context: context, title: title);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7FFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_up_right_square,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '서점에서 보기',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

void showBookstoreSelectSheet({
  required BuildContext context,
  required String title,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final searchTitle = _getSearchTitle(title);
  final encodedTitle = Uri.encodeComponent(searchTitle);

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
                    '서점 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$searchTitle" 검색',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  _BookstoreButton(
                    isDark: isDark,
                    logoPath: 'assets/images/logo-aladin.png',
                    name: '알라딘',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final url =
                          'https://www.aladin.co.kr/search/wsearchresult.aspx?SearchWord=$encodedTitle';
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                  const SizedBox(height: 12),
                  _BookstoreButton(
                    isDark: isDark,
                    logoPath: 'assets/images/logo-yes24.png',
                    name: 'Yes24',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final url =
                          'https://www.yes24.com/Product/Search?domain=ALL&query=$encodedTitle';
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                  const SizedBox(height: 12),
                  _BookstoreButton(
                    isDark: isDark,
                    logoPath: 'assets/images/logo-kyobo.svg',
                    name: '교보문고',
                    isSvg: true,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final url =
                          'https://search.kyobobook.co.kr/search?keyword=$encodedTitle';
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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

String _getSearchTitle(String title) {
  final hyphenIndex = title.indexOf(' - ');
  if (hyphenIndex > 0) {
    return title.substring(0, hyphenIndex).trim();
  }
  final dashIndex = title.indexOf('-');
  if (dashIndex > 0) {
    return title.substring(0, dashIndex).trim();
  }
  return title.trim();
}

class _BookstoreButton extends StatelessWidget {
  final bool isDark;
  final String logoPath;
  final String name;
  final VoidCallback onTap;
  final bool isSvg;

  const _BookstoreButton({
    required this.isDark,
    required this.logoPath,
    required this.name,
    required this.onTap,
    this.isSvg = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(4),
              child: isSvg
                  ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                  : Image.asset(logoPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
