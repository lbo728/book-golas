import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple HIG Liquid Glass 스타일 Bottom Navigation Bar
///
/// HIG_LIQUID_GLASS.md 참조:
/// - Liquid Glass 재질: 반투명 유리, 콘텐츠 위에 떠 있는 형태
/// - 적응형 색상: 아래 콘텐츠가 밝으면 어둡게, 어두우면 밝게
/// - 검색은 탭 막대 뒤쪽 끝에 시각적으로 구별된 탭으로 배치
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

  // 탭 설정 (4개 네비게이션 탭 + 1개 검색 탭)
  static const List<_TabItemData> _navigationTabs = [
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

  // 검색 탭 (뒤쪽 끝에 시각적으로 구별)
  static const _TabItemData _searchTab = _TabItemData(
    icon: CupertinoIcons.search,
    activeIcon: CupertinoIcons.search,
    label: '검색',
  );

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
    // HIG: 아래 콘텐츠에 반응하여 라이트/다크 모드로 조정
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: _buildLiquidGlassTabBar(isDark),
    );
  }

  /// Liquid Glass 효과가 적용된 TabBar (검색 탭 포함)
  /// HIG: "탭 막대의 뒤쪽 끝에는 별도의 검색 항목을 포함할 수 있습니다"
  Widget _buildLiquidGlassTabBar(bool isDark) {
    // HIG 적응형 색상: 아래 콘텐츠가 밝으면 어둡게, 어두우면 밝게
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12) // 어두운 배경 → 밝은 글래스
        : Colors.black.withValues(alpha: 0.08); // 밝은 배경 → 어두운 글래스

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    // HIG: 아이콘/텍스트는 모노크롬 색상 체계
    final foregroundColor = isDark ? Colors.white : Colors.black;
    final inactiveForegroundColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 네비게이션 탭 영역과 검색 탭 영역 분리
              final totalTabs = _navigationTabs.length + 1; // +1 for search
              final tabWidth = constraints.maxWidth / totalTabs;

              return Stack(
                children: [
                  // 슬라이딩 인디케이터 (네비게이션 탭만)
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
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // 탭 아이템들 (네비게이션 탭 + 구분선 + 검색 탭)
                  Row(
                    children: [
                      // 네비게이션 탭들
                      ...List.generate(_navigationTabs.length, (index) {
                        return Expanded(
                          child: _buildTabItem(
                            index,
                            _navigationTabs[index],
                            foregroundColor,
                            inactiveForegroundColor,
                            isSearchTab: false,
                          ),
                        );
                      }),
                      // 검색 탭 (뒤쪽 끝, 시각적으로 구별)
                      _buildSearchTab(
                        tabWidth,
                        foregroundColor,
                        inactiveForegroundColor,
                        isDark,
                      ),
                    ],
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
  Widget _buildTabItem(
    int index,
    _TabItemData tab,
    Color foregroundColor,
    Color inactiveForegroundColor, {
    required bool isSearchTab,
  }) {
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
                  color: isSelected ? foregroundColor : inactiveForegroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color:
                      isSelected ? foregroundColor : inactiveForegroundColor,
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

  /// 검색 탭 (탭 막대 뒤쪽 끝에 시각적으로 구별된 탭)
  /// HIG: "검색을 탭 막대의 뒤쪽에 시각적으로 구별된 탭으로 배치할 수 있습니다"
  Widget _buildSearchTab(
    double tabWidth,
    Color foregroundColor,
    Color inactiveForegroundColor,
    bool isDark,
  ) {
    // 구분선 색상
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    return SizedBox(
      width: tabWidth,
      child: Row(
        children: [
          // 시각적 구분선
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
          // 검색 탭 아이템
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSearchTap();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchTab.icon,
                      color: inactiveForegroundColor,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _searchTab.label,
                      style: TextStyle(
                        color: inactiveForegroundColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
