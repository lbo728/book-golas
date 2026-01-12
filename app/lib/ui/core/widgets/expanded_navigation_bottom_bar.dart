import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandedNavigationBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onBackToReadingDetail;
  final VoidCallback onUpdatePageTap;
  final void Function(Offset position, double size) onSearchTap;

  static const List<_MenuItemData> _menuItems = [
    _MenuItemData(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: '홈',
    ),
    _MenuItemData(
      icon: CupertinoIcons.book,
      activeIcon: CupertinoIcons.book_fill,
      label: '독서 상태',
    ),
    _MenuItemData(
      icon: CupertinoIcons.calendar,
      activeIcon: CupertinoIcons.calendar,
      label: '독서 캘린더',
    ),
    _MenuItemData(
      icon: CupertinoIcons.person_crop_circle,
      activeIcon: CupertinoIcons.person_crop_circle_fill,
      label: '마이페이지',
    ),
  ];

  final GlobalKey _searchButtonKey = GlobalKey();

  ExpandedNavigationBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onBackToReadingDetail,
    required this.onUpdatePageTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final foregroundColor = isDark ? Colors.white : Colors.black;
    final inactiveForegroundColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(
                      isDark,
                      foregroundColor,
                      inactiveForegroundColor,
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(_menuItems.length, (index) {
                      final isSelected = selectedIndex == index;
                      return _buildMenuItem(
                        index,
                        _menuItems[index],
                        isSelected,
                        foregroundColor,
                        inactiveForegroundColor,
                        highlightColor,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSearchButton(isDark, glassColor, borderColor),
      ],
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color foregroundColor,
    Color inactiveForegroundColor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onBackToReadingDetail();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.arrow_left,
              size: 18,
              color: inactiveForegroundColor,
            ),
            const SizedBox(width: 12),
            Text(
              '페이지 업데이트',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: inactiveForegroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    _MenuItemData item,
    bool isSelected,
    Color foregroundColor,
    Color inactiveForegroundColor,
    Color highlightColor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? highlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 20,
              color: isSelected ? foregroundColor : inactiveForegroundColor,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? foregroundColor : inactiveForegroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(
    bool isDark,
    Color glassColor,
    Color borderColor,
  ) {
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.7);

    const buttonSize = 62.0;

    return GestureDetector(
      key: _searchButtonKey,
      onTap: () {
        HapticFeedback.selectionClick();
        final RenderBox? renderBox =
            _searchButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          onSearchTap(position, buttonSize);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: borderColor,
                width: 0.5,
              ),
            ),
            child: Icon(
              CupertinoIcons.search,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _MenuItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
