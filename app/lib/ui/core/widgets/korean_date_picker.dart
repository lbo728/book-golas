import 'package:flutter/material.dart';

import 'package:book_golas/l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWheel(
          items: _years,
          controller: _yearController,
          suffix: localizations.koreanDatePickerYear,
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
          suffix: localizations.koreanDatePickerMonth,
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
          suffix: localizations.koreanDatePickerDay,
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
