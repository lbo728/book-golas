import 'package:flutter/material.dart';

import 'package:book_golas/ui/core/widgets/glass_text_field.dart';

class TodayGoalSheet {
  /// 오늘의 분량 설정 시트 표시
  ///
  /// [context] - BuildContext
  /// [initialStartPage] - 초기 시작 페이지
  /// [initialTargetPage] - 초기 목표 페이지
  /// [onSave] - 저장 콜백 (시작 페이지, 목표 페이지)
  static void show({
    required BuildContext context,
    int? initialStartPage,
    int? initialTargetPage,
    required Function(int startPage, int targetPage) onSave,
  }) {
    final startController =
        TextEditingController(text: initialStartPage?.toString() ?? '');
    final endController =
        TextEditingController(text: initialTargetPage?.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                '오늘의 분량 설정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              GlassTextField(
                controller: startController,
                keyboardType: TextInputType.number,
                label: '시작 페이지',
                hint: '시작 페이지 입력',
                prefixIcon: Icons.first_page_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: endController,
                keyboardType: TextInputType.number,
                label: '목표 페이지',
                hint: '목표 페이지 입력',
                prefixIcon: Icons.last_page_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final start = int.tryParse(startController.text);
                    final end = int.tryParse(endController.text);
                    if (start != null && end != null && start < end) {
                      onSave(start, end);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
