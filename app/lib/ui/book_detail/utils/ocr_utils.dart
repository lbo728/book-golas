import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';
import 'package:book_golas/data/services/google_vision_ocr_service.dart';

int? extractPageNumber(String text) {
  final patterns = [
    RegExp(r'[-–]\s*(\d{1,4})\s*[-–]'),
    RegExp(r'[pP]\.?\s*(\d{1,4})'),
    RegExp(r'[pP]age\s*(\d{1,4})', caseSensitive: false),
    RegExp(r'(\d{1,4})\s*페이지'),
    RegExp(r'(\d{1,4})\s*쪽'),
    RegExp(r'^\s*(\d{1,4})\s*$', multiLine: true),
    RegExp(r'^(\d{1,4})\s+\S', multiLine: true),
    RegExp(r'\S\s+(\d{1,4})$', multiLine: true),
    RegExp(r'\((\d{1,4})\)'),
    RegExp(r'\[(\d{1,4})\]'),
    RegExp(r'^(\d{1,4})\b'),
    RegExp(r'\b(\d{1,4})$'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      final pageStr = match.group(1);
      if (pageStr != null) {
        final page = int.tryParse(pageStr);
        if (page != null && page > 0 && page < 10000) {
          final matchStart = match.start;
          if (matchStart > 0 && text[matchStart - 1] == '.') {
            continue;
          }
          final matchEnd = match.end;
          if (matchEnd < text.length && text[matchEnd] == '.') {
            continue;
          }
          return page;
        }
      }
    }
  }
  return null;
}

Future<void> extractTextFromLocalImage(
  BuildContext context,
  Uint8List imageBytes,
  Function(String extractedText, int? pageNumber) onComplete,
) async {
  bool isLoadingDialogShown = false;
  final parentContext = context;

  try {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);

    debugPrint('🟡 OCR: 크롭 화면 표시 중...');
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      uiSettings: [
        IOSUiSettings(
          title: '텍스트 추출 영역 선택',
          cancelButtonTitle: '취소',
          doneButtonTitle: '완료',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
        AndroidUiSettings(
          toolbarTitle: '텍스트 추출 영역 선택',
          toolbarColor: const Color(0xFF5B7FFF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    try {
      await tempFile.delete();
    } catch (_) {}

    if (croppedFile == null) {
      debugPrint('🟠 OCR: 사용자가 크롭을 취소했습니다.');
      return;
    }

    debugPrint('🟡 OCR: 크롭 완료, 텍스트 추출 시작...');
    isLoadingDialogShown = true;
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF5B7FFF)),
                const SizedBox(height: 16),
                Text(
                  '텍스트 추출 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(dialogContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final ocrService = GoogleVisionOcrService();
    final croppedBytes = await croppedFile.readAsBytes();
    debugPrint('🟡 OCR: 크롭된 이미지 크기: ${croppedBytes.length} bytes');

    final ocrText = await ocrService.extractTextFromBytes(croppedBytes);
    final pageNumber = extractPageNumber(ocrText ?? '');

    if (isLoadingDialogShown) {
      Navigator.of(parentContext, rootNavigator: true).pop();
      isLoadingDialogShown = false;
    }

    if (ocrText == null || ocrText.isEmpty) {
      debugPrint('🟠 OCR: 텍스트 추출 결과가 비어있습니다.');
      CustomSnackbar.show(parentContext, message: '텍스트를 추출하지 못했습니다. 다른 영역을 선택해보세요.', rootOverlay: true);
      return;
    }

    debugPrint('🟢 OCR: 텍스트 추출 성공 (길이: ${ocrText.length})');
    onComplete(ocrText, pageNumber);
  } catch (e) {
    debugPrint('🔴 OCR: 예외 발생 - $e');

    if (isLoadingDialogShown) {
      try {
        Navigator.of(parentContext, rootNavigator: true).pop();
      } catch (_) {}
    }

    CustomSnackbar.show(parentContext, message: '텍스트 추출에 실패했습니다. 다시 시도해주세요.', rootOverlay: true);
  }
}

Future<void> pickImageAndExtractText(
  BuildContext context,
  ImageSource source,
  Function(Uint8List imageBytes, String ocrText, int? pageNumber) onComplete,
) async {
  bool isLoadingDialogShown = false;
  final parentContext = context;

  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final fullImageBytes = await pickedFile.readAsBytes();

    await Future.delayed(const Duration(milliseconds: 100));

    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final shouldExtract = await showModalBottomSheet<bool>(
      context: parentContext,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                Icons.document_scanner_outlined,
                size: 48,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                '텍스트를 추출하시겠어요?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '크레딧이 소모됩니다',
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
                      onPressed: () => Navigator.pop(context, false),
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
                        '괜찮아요',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '추출할게요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );

    if (shouldExtract != true) {
      onComplete(fullImageBytes, '', null);
      return;
    }

    debugPrint('🟡 OCR: 크롭 화면 표시 중...');
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        IOSUiSettings(
          title: '텍스트 추출 영역 선택',
          cancelButtonTitle: '취소',
          doneButtonTitle: '완료',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
        AndroidUiSettings(
          toolbarTitle: '텍스트 추출 영역 선택',
          toolbarColor: const Color(0xFF5B7FFF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    if (croppedFile == null) {
      debugPrint('🟠 OCR: 사용자가 크롭을 취소했습니다.');
      return;
    }

    debugPrint('🟡 OCR: 크롭 완료, 텍스트 추출 시작...');
    isLoadingDialogShown = true;
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF5B7FFF)),
                const SizedBox(height: 16),
                Text(
                  '텍스트 추출 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(dialogContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final ocrService = GoogleVisionOcrService();
    final croppedBytes = await croppedFile.readAsBytes();
    debugPrint('🟡 OCR: 크롭된 이미지 크기: ${croppedBytes.length} bytes');

    final ocrText = await ocrService.extractTextFromBytes(croppedBytes);
    final pageNumber = extractPageNumber(ocrText ?? '');

    if (isLoadingDialogShown) {
      Navigator.of(parentContext, rootNavigator: true).pop();
      isLoadingDialogShown = false;
    }

    if (ocrText == null || ocrText.isEmpty) {
      debugPrint('🟠 OCR: 텍스트 추출 결과가 비어있습니다.');
      CustomSnackbar.show(parentContext, message: '텍스트를 추출하지 못했습니다. 다른 영역을 선택해보세요.', rootOverlay: true);
      return;
    }

    debugPrint('🟢 OCR: 텍스트 추출 성공 (길이: ${ocrText.length})');
    onComplete(fullImageBytes, ocrText, pageNumber);
  } catch (e) {
    debugPrint('🔴 OCR: 예외 발생 - $e');

    if (isLoadingDialogShown) {
      try {
        Navigator.of(parentContext, rootNavigator: true).pop();
      } catch (_) {}
    }

    CustomSnackbar.show(parentContext, message: '텍스트 추출에 실패했습니다. 다시 시도해주세요.', rootOverlay: true);
  }
}

Future<void> reExtractTextFromImage(
  BuildContext context, {
  required String imageUrl,
  required Function(String extractedText) onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final shouldProceed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            '텍스트를 추출하시겠어요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '작성하신 텍스트를 덮어씁니다.\n크레딧을 소모합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(bottomSheetContext, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(bottomSheetContext, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '추출하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 8),
        ],
      ),
    ),
  );

  if (shouldProceed != true) return;

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF5B7FFF)),
                const SizedBox(height: 16),
                Text(
                  '이미지 불러오는 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(dialogContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(imageUrl));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);

    Navigator.of(context, rootNavigator: true).pop();

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      uiSettings: [
        IOSUiSettings(
          title: '텍스트 추출 영역 선택',
          cancelButtonTitle: '취소',
          doneButtonTitle: '완료',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
        AndroidUiSettings(
          toolbarTitle: '텍스트 추출 영역 선택',
          toolbarColor: const Color(0xFF5B7FFF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    await tempFile.delete();

    if (croppedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF5B7FFF)),
                const SizedBox(height: 16),
                Text(
                  '텍스트 추출 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(dialogContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final ocrService = GoogleVisionOcrService();
    final croppedBytes = await croppedFile.readAsBytes();
    final ocrText = await ocrService.extractTextFromBytes(croppedBytes) ?? '';

    Navigator.of(context, rootNavigator: true).pop();

    onConfirm(ocrText);
  } catch (e) {
    Navigator.of(context, rootNavigator: true).pop();
    CustomSnackbar.show(context, message: '텍스트 다시 추출에 실패했습니다.', rootOverlay: true);
  }
}
