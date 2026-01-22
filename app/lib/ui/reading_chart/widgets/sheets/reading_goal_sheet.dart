import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 연간 독서 목표 설정 바텀시트
///
/// 온보딩 및 설정 화면에서 연간 독서 목표를 설정하는 바텀시트
class ReadingGoalSheet {
  /// 연간 목표 설정 바텀시트 표시
  ///
  /// [context] - BuildContext
  /// [year] - 목표 연도
  /// [currentGoal] - 현재 설정된 목표 (수정 시)
  /// [onSave] - 저장 콜백 (목표 권수)
  static Future<int?> show({
    required BuildContext context,
    required int year,
    int? currentGoal,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedGoal = currentGoal ?? 24;
    final TextEditingController customController = TextEditingController();
    bool useCustom = false;

    final presetGoals = [12, 24, 36, 50];

    return await showModalBottomSheet<int>(
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
                  Row(
                    children: [
                      Text(
                        '📚',
                        style: TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$year년 독서 목표',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '올해 몇 권의 책을 읽고 싶으세요?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '추천 목표',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: presetGoals.map((goal) {
                      final isSelected = !useCustom && selectedGoal == goal;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: goal != presetGoals.last ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedGoal = goal;
                                useCustom = false;
                                customController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF5B7FFF)
                                    : (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5B7FFF)
                                      : (isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$goal',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  ),
                                  Text(
                                    '권',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white70
                                          : (isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '직접 입력',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getGoalMessage(selectedGoal),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          selectedGoal = parsed;
                          useCustom = true;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '목표 권수 입력',
                      suffixText: '권',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B7FFF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: const Color(0xFF5B7FFF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getMotivationMessage(selectedGoal),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
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
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedGoal > 0
                              ? () => Navigator.pop(context, selectedGoal)
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
                            currentGoal != null ? '목표 수정' : '목표 설정',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

  static String _getGoalMessage(int goal) {
    final booksPerMonth = (goal / 12).toStringAsFixed(1);
    return '월 평균 $booksPerMonth권';
  }

  static String _getMotivationMessage(int goal) {
    if (goal <= 12) {
      return '월 1권씩 꾸준히 읽으면 달성할 수 있어요! 무리하지 않고 독서 습관을 만들어보세요.';
    } else if (goal <= 24) {
      return '2주에 1권씩 읽으면 달성 가능해요! 적당한 목표로 독서의 즐거움을 느껴보세요.';
    } else if (goal <= 36) {
      return '열흘에 1권! 독서를 사랑하시는군요. 다양한 장르를 탐험해보세요!';
    } else if (goal <= 50) {
      return '주 1권에 가까운 목표네요! 진정한 독서광의 길을 걷고 계시군요. 🔥';
    } else {
      return '대단한 목표입니다! 일주일에 1권 이상 읽는 독서 마스터를 향해! 📚✨';
    }
  }
}
