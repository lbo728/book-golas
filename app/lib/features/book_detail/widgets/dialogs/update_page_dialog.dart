import 'package:flutter/material.dart';

/// 현재 페이지 업데이트 다이얼로그
///
/// 사용자가 현재 읽은 페이지를 업데이트할 수 있는 바텀시트
class UpdatePageDialog {
  /// 페이지 업데이트 다이얼로그 표시
  ///
  /// [context] - BuildContext
  /// [currentPage] - 현재 페이지
  /// [totalPages] - 총 페이지
  /// [onUpdate] - 업데이트 완료 콜백 (새 페이지 번호 전달)
  static Future<void> show({
    required BuildContext context,
    required int currentPage,
    required int totalPages,
    required Function(int newPage) onUpdate,
  }) async {
    final TextEditingController controller = TextEditingController(text: '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? errorText;
    bool isValid = false;

    String? validatePage(String value) {
      if (value.isEmpty) {
        return null;
      }
      final page = int.tryParse(value);
      if (page == null) {
        return '숫자를 입력해주세요';
      }
      if (page < 0) {
        return '0 이상의 페이지를 입력해주세요';
      }
      if (page > totalPages) {
        return '총 페이지($totalPages)를 초과할 수 없습니다';
      }
      if (page <= currentPage) {
        return '현재 페이지($currentPage) 이하입니다';
      }
      return null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 페이지 업데이트',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '현재 ${currentPage}p',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B7FFF),
                        ),
                      ),
                      Text(
                        ' / 총 ${totalPages}p',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (value) {
                      setModalState(() {
                        errorText = validatePage(value);
                        isValid = errorText == null && value.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '새 페이지 번호',
                      hintText: '${currentPage + 1} ~ $totalPages',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorText != null
                              ? Colors.red
                              : const Color(0xFF5B7FFF),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () {
                                  final page = int.parse(controller.text);
                                  Navigator.pop(context);
                                  onUpdate(page);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            disabledBackgroundColor:
                                isDark ? Colors.grey[700] : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '업데이트',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isValid
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
