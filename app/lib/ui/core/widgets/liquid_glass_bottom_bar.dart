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
/// - 물방울 확대 애니메이션: 선택된 탭이 위로 확대되며 미끄러지듯 이동
class LiquidGlassBottomBar extends StatefulWidget {
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
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  int _previousIndex = 0;

  // 탭 설정
  static const List<_TabItemData> _tabs = [
    _TabItemData(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: '홈',
    ),
    _TabItemData(
      icon: CupertinoIcons.book,
      activeIcon: CupertinoIcons.book_fill,
      label: '독서 상태',
    ),
    _TabItemData(
      icon: CupertinoIcons.calendar,
      activeIcon: CupertinoIcons.calendar,
      label: '독서캘린더',
    ),
    _TabItemData(
      icon: CupertinoIcons.person_crop_circle,
      activeIcon: CupertinoIcons.person_crop_circle_fill,
      label: '마이페이지',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(LiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _slideAnimation = Tween<double>(
        begin: _previousIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      borderRadius: BorderRadius.circular(100), // Full radius
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(100), // Full radius
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _tabs.length;

              return Stack(
                children: [
                  // 슬라이딩 인디케이터 (물방울 배경)
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: _slideAnimation.value * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: tabWidth - 8,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // 탭 아이템들
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      return Expanded(
                        child: _buildTabItem(index, _tabs[index]),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 개별 탭 아이템 (물방울 확대 애니메이션)
  Widget _buildTabItem(int index, _TabItemData tab) {
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          // 현재 애니메이션 진행 중인 위치와의 거리 계산
          final distance = (_slideAnimation.value - index).abs();
          final isNear = distance < 1.0;

          // 물방울 확대 효과: 가까울수록 확대
          final scale = isNear ? 1.0 + (1.0 - distance) * 0.1 : 1.0;
          // 위로 올라오는 효과
          final translateY = isNear ? -(1.0 - distance) * 4 : 0.0;

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  key: ValueKey('${index}_$isSelected'),
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 원형 검색 버튼 (Liquid Glass 효과)
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onSearchTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
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

/// 탭 아이템 데이터
class _TabItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
