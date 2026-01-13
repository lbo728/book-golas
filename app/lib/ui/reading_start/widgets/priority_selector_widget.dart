import 'package:flutter/material.dart';

class PrioritySelectorWidget extends StatelessWidget {
  final int? selectedPriority;
  final ValueChanged<int?> onPriorityChanged;
  final bool isDark;

  const PrioritySelectorWidget({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우선순위 (선택사항)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPriorityButton(1, '긴급', const Color(0xFFFF3B30)),
            const SizedBox(width: 8),
            _buildPriorityButton(2, '높음', const Color(0xFFFF9500)),
            const SizedBox(width: 8),
            _buildPriorityButton(3, '보통', const Color(0xFF5B7FFF)),
            const SizedBox(width: 8),
            _buildPriorityButton(4, '낮음', const Color(0xFF34C759)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityButton(int priority, String label, Color color) {
    final isSelected = selectedPriority == priority;

    return Expanded(
      child: GestureDetector(
        onTap: () => onPriorityChanged(isSelected ? null : priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
