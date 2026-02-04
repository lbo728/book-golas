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

  String _getMonthName(int month, AppLocalizations l10n) {
    switch (month) {
      case 1:
        return l10n.datePickerMonthJan;
      case 2:
        return l10n.datePickerMonthFeb;
      case 3:
        return l10n.datePickerMonthMar;
      case 4:
        return l10n.datePickerMonthApr;
      case 5:
        return l10n.datePickerMonthMay;
      case 6:
        return l10n.datePickerMonthJun;
      case 7:
        return l10n.datePickerMonthJul;
      case 8:
        return l10n.datePickerMonthAug;
      case 9:
        return l10n.datePickerMonthSep;
      case 10:
        return l10n.datePickerMonthOct;
      case 11:
        return l10n.datePickerMonthNov;
      case 12:
        return l10n.datePickerMonthDec;
      default:
        return '$month';
    }
  }

  Widget _buildWheel({
    required List<int> items,
    required FixedExtentScrollController controller,
    required String Function(int) formatter,
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
                formatter(items[index]),
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
    final locale = Localizations.localeOf(context);
    final isKorean = locale.languageCode == 'ko';

    // Year wheel
    final yearWheel = _buildWheel(
      items: _years,
      controller: _yearController,
      formatter: (year) => '$year${localizations.koreanDatePickerYear}',
      width: isKorean ? 90 : 80,
      onSelected: (year) {
        setState(() {
          _currentYear = year;
        });
        _onDatePartChanged();
      },
    );

    // Month wheel
    final monthWheel = _buildWheel(
      items: _months,
      controller: _monthController,
      formatter: (month) => isKorean
          ? '$month${localizations.koreanDatePickerMonth}'
          : _getMonthName(month, localizations),
      width: isKorean ? 70 : 60,
      onSelected: (month) {
        setState(() {
          _currentMonth = month;
        });
        _onDatePartChanged();
      },
    );

    // Day wheel
    final dayWheel = _buildWheel(
      items: List.generate(daysInCurrentMonth, (i) => i + 1),
      controller: _dayController,
      formatter: (day) => '$day${localizations.koreanDatePickerDay}',
      width: isKorean ? 70 : 50,
      onSelected: (day) {
        setState(() {
          _currentDay = day;
        });
        _onDatePartChanged();
      },
    );

    // Korean: Year - Month - Day
    // English: Day - Month - Year
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: isKorean
          ? [yearWheel, monthWheel, dayWheel]
          : [dayWheel, monthWheel, yearWheel],
    );
  }
}
