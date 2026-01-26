import 'package:book_golas/ui/core/theme/design_system.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';

enum ImageSourceType {
  camera,
  gallery,
  documentScan,
}

Future<ImageSourceType?> showImageSourceSheet({
  required BuildContext context,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isCameraAvailable = !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      (Platform.isAndroid || (Platform.isIOS && !Platform.isMacOS));

  return showModalBottomSheet<ImageSourceType>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_viewfinder,
                    color: AppColors.success,
                  ),
                ),
                title: Text(
                  '문서 스캔',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  '평탄화 및 자동 보정',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: isCameraAvailable && Platform.isIOS
                    ? () => Navigator.pop(
                        sheetContext, ImageSourceType.documentScan)
                    : () {
                        Navigator.pop(sheetContext);
                        CustomSnackbar.show(
                          context,
                          message: '시뮬레이터에서는 카메라를 사용할 수 없습니다',
                          type: SnackbarType.warning,
                        );
                      },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  '카메라 촬영하기',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  '일반 촬영',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: isCameraAvailable && Platform.isIOS
                    ? () => Navigator.pop(sheetContext, ImageSourceType.camera)
                    : () {
                        Navigator.pop(sheetContext);
                        CustomSnackbar.show(
                          context,
                          message: '시뮬레이터에서는 카메라를 사용할 수 없습니다',
                          type: SnackbarType.warning,
                        );
                      },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.photo_fill,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  '라이브러리에서 가져오기',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  '저장된 이미지 선택',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageSourceType.gallery),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

Future<ImageSource?> showImageReplaceOptionsSheet({
  required BuildContext context,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '이미지 교체',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.camera,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.photo,
                  color: AppColors.success,
                ),
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> showReplaceImageConfirmationSheet({
  required BuildContext context,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 32,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '이미지를 교체하시겠습니까?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '기존에 추출한 텍스트가 사라집니다.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '교체하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
