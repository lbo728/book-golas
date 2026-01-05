import 'package:flutter/material.dart';

/// 스케줄 미리보기 위젯
/// 목표일수, 하루 목표 페이지, 예상 스케줄을 표시합니다.
class SchedulePreviewWidget extends StatefulWidget {
  final int totalPages;
  final DateTime startDate;
  final DateTime targetDate;
  final int? dailyTargetPages;
  final bool isDark;
  final VoidCallback? onChangeSchedule;

  const SchedulePreviewWidget({
    super.key,
    required this.totalPages,
    required this.startDate,
    required this.targetDate,
    this.dailyTargetPages,
    required this.isDark,
    this.onChangeSchedule,
  });

  @override
  State<SchedulePreviewWidget> createState() => _SchedulePreviewWidgetState();
}

class _SchedulePreviewWidgetState extends State<SchedulePreviewWidget> {
  bool _isExpanded = false;

  int get targetDays {
    final days = widget.targetDate.difference(widget.startDate).inDays;
    return days > 0 ? days : 1;
  }

  int get calculatedDailyTarget {
    if (widget.dailyTargetPages != null) return widget.dailyTargetPages!;
    return (widget.totalPages / targetDays).ceil();
  }

  List<Map<String, dynamic>> get schedule {
    final result = <Map<String, dynamic>>[];
    int remainingPages = widget.totalPages;
    DateTime currentDate = widget.startDate;
    final dailyTarget = calculatedDailyTarget;

    while (remainingPages > 0 &&
        !currentDate.isAfter(widget.targetDate.add(const Duration(days: 30)))) {
      int pagesToRead;
      if (result.isEmpty) {
        pagesToRead = dailyTarget;
      } else {
        final daysRemaining =
            widget.targetDate.difference(currentDate).inDays + 1;
        if (daysRemaining > 0) {
          pagesToRead = (remainingPages / daysRemaining).ceil();
        } else {
          pagesToRead = remainingPages;
        }
      }
      pagesToRead = pagesToRead.clamp(1, remainingPages);

      final weekday =
          ['월', '화', '수', '목', '금', '토', '일'][currentDate.weekday - 1];
      final now = DateTime.now();
      final isToday = currentDate.day == now.day &&
          currentDate.month == now.month &&
          currentDate.year == now.year;

      result.add({
        'date': currentDate,
        'weekday': weekday,
        'pages': pagesToRead,
        'isToday': isToday,
      });

      remainingPages -= pagesToRead;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildSummary(),
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            _buildScheduleList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                icon: Icons.calendar_today_outlined,
                label: '목표 일수',
                value: '$targetDays일',
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                icon: Icons.auto_stories_outlined,
                label: '하루 목표',
                value: '$calculatedDailyTarget페이지',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: widget.isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isExpanded ? '스케줄 접기' : '예상 스케줄 보기',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onChangeSchedule != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onChangeSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: const Color(0xFF5B7FFF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '변경',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B7FFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF5B7FFF),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      widget.isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final scheduleItems = schedule.take(7).toList();
    final hasMore = schedule.length > 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...scheduleItems.map((item) => _buildScheduleItem(item)),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${schedule.length - 7}일 더...',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    final date = item['date'] as DateTime;
    final weekday = item['weekday'] as String;
    final pages = item['pages'] as int;
    final isToday = item['isToday'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(
              '${date.month}/${date.day} ($weekday)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                color: isToday
                    ? const Color(0xFF5B7FFF)
                    : (widget.isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (pages / calculatedDailyTarget).clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF5B7FFF)
                          : (widget.isDark
                              ? Colors.white38
                              : Colors.black26),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$pages p',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isToday
                    ? const Color(0xFF5B7FFF)
                    : (widget.isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
