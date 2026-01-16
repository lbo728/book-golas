import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KoreanYearMonthPicker extends StatefulWidget {
  final bool isDark;
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  const KoreanYearMonthPicker({
    super.key,
    required this.isDark,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<KoreanYearMonthPicker> createState() => _KoreanYearMonthPickerState();
}

class _KoreanYearMonthPickerState extends State<KoreanYearMonthPicker> {
  late int _currentYear;
  late int _currentMonth;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  final List<int> _years =
      List.generate(11, (i) => DateTime.now().year - 5 + i);
  final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _currentYear = widget.selectedDate.year;
    _currentMonth = widget.selectedDate.month;

    final yearIndex = _years.indexOf(_currentYear);
    _yearController = FixedExtentScrollController(
      initialItem: yearIndex >= 0 ? yearIndex : 5,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _currentMonth - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  void _onDatePartChanged() {
    final newDate = DateTime(_currentYear, _currentMonth, 1);
    widget.onDateChanged(newDate);
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
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          onSelected(items[index]);
        },
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
      ],
    );
  }
}
