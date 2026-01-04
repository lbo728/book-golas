import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinearBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSearchTap;

  const LinearBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavIcon(
            index: 0,
            icon: CupertinoIcons.house_fill,
            inactiveIcon: CupertinoIcons.house,
          ),
          _buildNavIcon(
            index: 1,
            icon: CupertinoIcons.chart_bar_square_fill,
            inactiveIcon: CupertinoIcons.chart_bar_square,
          ),
          _buildNavIcon(
            index: 2,
            icon: CupertinoIcons.person_crop_circle_fill,
            inactiveIcon: CupertinoIcons.person_crop_circle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2C2C2E)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            isSelected ? icon : inactiveIcon,
            key: ValueKey(isSelected),
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSearchTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search workspace',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
