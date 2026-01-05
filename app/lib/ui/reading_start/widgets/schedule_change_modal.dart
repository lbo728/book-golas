import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 스케줄 변경 모달
/// 하루 목표 페이지를 변경하고 예상 완료일을 확인할 수 있습니다.
class ScheduleChangeModal {
  static Future<int?> show({
    required BuildContext context,
    required int totalPages,
    required DateTime startDate,
    required DateTime targetDate,
    int? currentDailyTarget,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = targetDate.difference(startDate).inDays;
    final defaultDailyTarget = days > 0 ? (totalPages / days).ceil() : totalPages;
    int dailyTarget = currentDailyTarget ?? defaultDailyTarget;

    final wheelController = FixedExtentScrollController(
      initialItem: dailyTarget - 1,
    );

    return await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 예상 완료일 계산
            final estimatedDays = (totalPages / dailyTarget).ceil();
            final estimatedEndDate = startDate.add(Duration(days: estimatedDays));

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // 드래그 핸들
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                    // 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_calendar_outlined,
                              color: Color(0xFF5B7FFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '하루 목표 변경',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  '총 $totalPages 페이지',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 다이얼 피커
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 선택 영역 하이라이트
                          Container(
                            width: 80,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF5B7FFF).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          // 수평 휠 피커
                          RotatedBox(
                            quarterTurns: 3,
                            child: ListWheelScrollView.useDelegate(
                              controller: wheelController,
                              itemExtent: 60,
                              perspective: 0.003,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                HapticFeedback.lightImpact();
                                setModalState(() {
                                  dailyTarget = index + 1;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: totalPages.clamp(1, 500),
                                builder: (context, index) {
                                  final value = index + 1;
                                  final isSelected = value == dailyTarget;
                                  return RotatedBox(
                                    quarterTurns: 1,
                                    child: Center(
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 18,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? const Color(0xFF5B7FFF)
                                              : (isDark
                                                  ? Colors.white38
                                                  : Colors.black26),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '페이지 / 일',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 예상 완료일 정보
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '예상 완료일: ${estimatedEndDate.month}월 ${estimatedEndDate.day}일',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($estimatedDays일)',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 적용 버튼
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, dailyTarget);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '적용하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SafeArea 대신 수동 하단 패딩
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              );
          },
        );
      },
    );
  }
}
