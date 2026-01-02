import 'package:flutter/material.dart';

class UpdateTargetDateDialog extends StatefulWidget {
  final DateTime currentTargetDate;
  final int nextAttemptCount;
  final Future<void> Function(DateTime newDate, int newAttempt) onConfirm;

  const UpdateTargetDateDialog({
    super.key,
    required this.currentTargetDate,
    required this.nextAttemptCount,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime currentTargetDate,
    required int nextAttemptCount,
    required Future<void> Function(DateTime newDate, int newAttempt) onConfirm,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateTargetDateDialog(
        currentTargetDate: currentTargetDate,
        nextAttemptCount: nextAttemptCount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<UpdateTargetDateDialog> createState() => _UpdateTargetDateDialogState();
}

class _UpdateTargetDateDialogState extends State<UpdateTargetDateDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentTargetDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysRemaining = _selectedDate.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildSelectedDateDisplay(isDark, daysRemaining),
          const SizedBox(height: 16),
          _buildDatePicker(isDark),
          const SizedBox(height: 24),
          _buildButtons(isDark),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_month,
            color: Color(0xFFFF6B6B),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '목표일 변경',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${widget.nextAttemptCount}번째 도전으로 변경됩니다',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateDisplay(bool isDark, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: daysRemaining > 0
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysRemaining > 0 ? 'D-$daysRemaining' : 'D-Day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: daysRemaining > 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFFF6B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: KoreanDatePicker(
        isDark: isDark,
        selectedDate: _selectedDate,
        minimumDate: DateTime.now(),
        onDateChanged: (newDate) {
          setState(() {
            _selectedDate = newDate;
          });
        },
      ),
    );
  }

  Widget _buildButtons(bool isDark) {
    return Row(
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
            onPressed: () async {
              Navigator.pop(context);
              await widget.onConfirm(_selectedDate, widget.nextAttemptCount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '변경하기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class KoreanDatePicker extends StatefulWidget {
  final bool isDark;
  final DateTime selectedDate;
  final DateTime minimumDate;
  final void Function(DateTime) onDateChanged;

  const KoreanDatePicker({
    super.key,
    required this.isDark,
    required this.selectedDate,
    required this.minimumDate,
    required this.onDateChanged,
  });

  @override
  State<KoreanDatePicker> createState() => _KoreanDatePickerState();
}

class _KoreanDatePickerState extends State<KoreanDatePicker> {
  late int _currentYear;
  late int _currentMonth;
  late int _currentDay;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  final List<int> _years = List.generate(10, (i) => DateTime.now().year + i);
  final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _currentYear = widget.selectedDate.year;
    _currentMonth = widget.selectedDate.month;
    _currentDay = widget.selectedDate.day;

    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_currentYear),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _currentMonth - 1,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _currentDay - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _onDatePartChanged() {
    final daysInMonth = _getDaysInMonth(_currentYear, _currentMonth);
    if (_currentDay > daysInMonth) {
      _currentDay = daysInMonth;
      _dayController.jumpToItem(_currentDay - 1);
    }

    final newDate = DateTime(_currentYear, _currentMonth, _currentDay);
    if (!newDate.isBefore(widget.minimumDate)) {
      widget.onDateChanged(newDate);
    }
  }

  Widget _buildWheel({
    required List<int> items,
    required FixedExtentScrollController controller,
    required String suffix,
    required Function(int) onSelected,
    double width = 80,
  }) {
    return SizedBox(
      width: width,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.5,
        perspective: 0.003,
        onSelectedItemChanged: (index) => onSelected(items[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            final isSelected = controller.hasClients
                ? controller.selectedItem == index
                : items.indexOf(items[index]) == controller.initialItem;
            return Center(
              child: Text(
                '${items[index]}$suffix',
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (widget.isDark ? Colors.white : Colors.black)
                      : (widget.isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInCurrentMonth = _getDaysInMonth(_currentYear, _currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWheel(
          items: _years,
          controller: _yearController,
          suffix: '년',
          width: 90,
          onSelected: (year) {
            setState(() {
              _currentYear = year;
            });
            _onDatePartChanged();
          },
        ),
        _buildWheel(
          items: _months,
          controller: _monthController,
          suffix: '월',
          width: 70,
          onSelected: (month) {
            setState(() {
              _currentMonth = month;
            });
            _onDatePartChanged();
          },
        ),
        _buildWheel(
          items: List.generate(daysInCurrentMonth, (i) => i + 1),
          controller: _dayController,
          suffix: '일',
          width: 70,
          onSelected: (day) {
            setState(() {
              _currentDay = day;
            });
            _onDatePartChanged();
          },
        ),
      ],
    );
  }
}
