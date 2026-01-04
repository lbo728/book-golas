import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple HIG Liquid Glass 스타일 Bottom Navigation Bar
///
/// TAB_BAR_LIQUID_GLASS_HIG.md 참조:
/// - Liquid Glass 재질: 반투명 유리 + 빛 반사/굴절 효과
/// - Floating: 콘텐츠 위에 떠 있는 느낌
/// - Tab Bar 역할: 네비게이션 전용
/// - 탭 개수: 3~5개 권장
class LiquidGlassBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSearchTap;

  const LiquidGlassBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Row(
        children: [
          // Pill TabBar (4개 탭)
          Expanded(
            child: _buildPillTabBar(),
          ),
          const SizedBox(width: 12),
          // 원형 검색 버튼
          _buildSearchButton(),
        ],
      ),
    );
  }

  /// Liquid Glass 효과가 적용된 Pill 형태 TabBar
  Widget _buildPillTabBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabItem(
                index: 0,
                icon: CupertinoIcons.house_fill,
                inactiveIcon: CupertinoIcons.house,
                label: '홈',
              ),
              _buildTabItem(
                index: 1,
                icon: CupertinoIcons.book_fill,
                inactiveIcon: CupertinoIcons.book,
                label: '독서 상태',
              ),
              _buildTabItem(
                index: 2,
                icon: CupertinoIcons.calendar,
                inactiveIcon: CupertinoIcons.calendar,
                label: '독서캘린더',
              ),
              _buildTabItem(
                index: 3,
                icon: CupertinoIcons.person_crop_circle_fill,
                inactiveIcon: CupertinoIcons.person_crop_circle,
                label: '마이페이지',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 개별 탭 아이템 (아이콘 + 라벨 항상 표시)
  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 원형 검색 버튼 (Liquid Glass 효과)
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSearchTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              CupertinoIcons.search,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
