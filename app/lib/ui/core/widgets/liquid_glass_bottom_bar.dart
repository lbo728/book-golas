import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple HIG Liquid Glass 스타일 Bottom Navigation Bar
///
/// HIG_LIQUID_GLASS.md 참조:
/// - Liquid Glass 재질: 반투명 유리, 콘텐츠 위에 떠 있는 형태
/// - 적응형 색상: 아래 콘텐츠가 밝으면 어둡게, 어두우면 밝게
/// - 검색 버튼: 분리된 원형 버튼, 탭 시 검색 필드 표시
/// - 물방울 확대 애니메이션: 롱프레스로 드래그하며 탭 전환
/// - 렌즈 효과: 물방울 영역 내 콘텐츠 굴절
class LiquidGlassBottomBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  /// 검색 버튼 탭 콜백: (버튼 위치, 버튼 크기) 전달
  final void Function(Offset position, double size)? onSearchTap;
  /// 검색 제출 콜백
  final ValueChanged<String>? onSearchSubmit;

  const LiquidGlassBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onSearchTap,
    this.onSearchSubmit,
  });

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  // 롱프레스 드래그 상태
  bool _isDragging = false;
  double _dragPosition = 0.0;
  double _tabWidth = 0.0;

  // 검색 버튼 위치 추적
  final GlobalKey _searchButtonKey = GlobalKey();

  // 검색 모드 상태
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchModeController;
  late Animation<double> _searchModeAnimation;

  // 탭 설정 (4개 네비게이션 탭)
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

    // 검색 모드 애니메이션 초기화
    _searchModeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _searchModeAnimation = CurvedAnimation(
      parent: _searchModeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(LiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isDragging) {
      _slideAnimation = Tween<double>(
        begin: _slideAnimation.value,
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
    _searchModeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 검색 모드 진입
  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    _searchModeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _searchFocusNode.requestFocus();
    });
  }

  /// 검색 모드 종료
  void _exitSearchMode() {
    _searchFocusNode.unfocus();
    _searchModeController.reverse().then((_) {
      setState(() {
        _isSearchMode = false;
        _searchController.clear();
      });
    });
  }

  /// 검색 제출
  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onSearchSubmit?.call(query);
      _exitSearchMode();
    }
  }

  /// 롱프레스 시작
  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = _slideAnimation.value;
    });
    HapticFeedback.mediumImpact();
  }

  /// 롱프레스 드래그 중
  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDragging || _tabWidth <= 0) return;

    final newPosition = details.localPosition.dx / _tabWidth;
    final clampedPosition = newPosition.clamp(0.0, (_tabs.length - 1).toDouble());

    setState(() {
      _dragPosition = clampedPosition;
    });

    // 탭 경계를 넘을 때 햅틱 피드백
    final currentTab = _dragPosition.round();
    final previousTab = (_dragPosition - 0.1).round();
    if (currentTab != previousTab) {
      HapticFeedback.selectionClick();
    }
  }

  /// 롱프레스 종료
  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isDragging) return;

    final targetIndex = _dragPosition.round().clamp(0, _tabs.length - 1);

    setState(() {
      _isDragging = false;
    });

    // 애니메이션으로 최종 위치로 이동
    _slideAnimation = Tween<double>(
      begin: _dragPosition,
      end: targetIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward(from: 0);

    // 탭 선택
    if (targetIndex != widget.selectedIndex) {
      widget.onTabSelected(targetIndex);
    }

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: AnimatedBuilder(
        animation: _searchModeAnimation,
        builder: (context, child) {
          // 검색 모드가 활성화되면 전체 바를 검색창으로 전환
          if (_isSearchMode || _searchModeAnimation.value > 0) {
            return _buildSearchModeBar(isDark);
          }

          return Row(
            children: [
              // Pill TabBar (4개 탭)
              Expanded(
                child: _buildLiquidGlassTabBar(isDark),
              ),
              const SizedBox(width: 12),
              // 분리된 원형 검색 버튼
              _buildSearchButton(isDark),
            ],
          );
        },
      ),
    );
  }

  /// 검색 모드 UI (전체 바가 검색창으로 변환)
  Widget _buildSearchModeBar(bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final foregroundColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // 취소 버튼 (좌측)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _exitSearchMode();
                },
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: foregroundColor.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 검색 입력 필드
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '책 제목 또는 저자 검색',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitSearch(),
                ),
              ),
              const SizedBox(width: 8),
              // 검색 버튼 (우측)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _submitSearch();
                },
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B7FFF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    CupertinoIcons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Liquid Glass 효과가 적용된 TabBar
  Widget _buildLiquidGlassTabBar(bool isDark) {
    // HIG 적응형 색상
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

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 62,
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
                _tabWidth = constraints.maxWidth / _tabs.length;

                return Stack(
                  children: [
                    // 물방울 인디케이터 (렌즈 효과)
                    _buildDropletIndicator(isDark, constraints.maxWidth),
                    // 탭 아이템들
                    Row(
                      children: List.generate(_tabs.length, (index) {
                        return Expanded(
                          child: _buildTabItem(
                            index,
                            _tabs[index],
                            foregroundColor,
                            inactiveForegroundColor,
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 물방울 인디케이터 (렌즈 효과 포함)
  Widget _buildDropletIndicator(bool isDark, double maxWidth) {
    final indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.12);

    // 렌즈 효과를 위한 하이라이트 색상
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        // 드래그 중이면 드래그 위치, 아니면 애니메이션 값 사용
        final currentPosition = _isDragging ? _dragPosition : _slideAnimation.value;
        final tabWidth = maxWidth / _tabs.length;

        return Positioned(
          left: currentPosition * tabWidth,
          top: 0,
          bottom: 0,
          width: tabWidth,
          child: Center(
            child: Container(
              width: tabWidth - 8,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                // 물방울 렌즈 효과: 그라디언트로 굴절 시뮬레이션
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    highlightColor,
                    indicatorColor,
                    indicatorColor.withValues(alpha: indicatorColor.a * 0.7),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
                // 내부 그림자로 깊이감
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // 내부 하이라이트 (상단 반사광)
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 개별 탭 아이템
  Widget _buildTabItem(
    int index,
    _TabItemData tab,
    Color foregroundColor,
    Color inactiveForegroundColor,
  ) {
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
          // 현재 위치 (드래그 중이면 드래그 위치 사용)
          final currentPosition = _isDragging ? _dragPosition : _slideAnimation.value;

          // 물방울과의 거리 계산 (0~1 범위로 정규화)
          final distance = (currentPosition - index).abs();

          // 물방울이 이 탭과 겹치는 정도 (0: 완전히 겹침, 1: 전혀 안겹침)
          final overlap = (1.0 - distance).clamp(0.0, 1.0);

          return _buildTabContent(
            index,
            tab,
            foregroundColor,
            inactiveForegroundColor,
            isSelected || overlap > 0.5,
          );
        },
        child: null,
      ),
    );
  }

  /// 탭 콘텐츠 (아이콘 + 라벨)
  Widget _buildTabContent(
    int index,
    _TabItemData tab,
    Color foregroundColor,
    Color inactiveForegroundColor,
    bool isHighlighted,
  ) {
    return SizedBox(
      height: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHighlighted ? tab.activeIcon : tab.icon,
            color: isHighlighted ? foregroundColor : inactiveForegroundColor,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              color: isHighlighted ? foregroundColor : inactiveForegroundColor,
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 분리된 원형 검색 버튼 (Liquid Glass 효과)
  Widget _buildSearchButton(bool isDark) {
    // 탭바와 동일한 색상
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      key: _searchButtonKey,
      onTap: () {
        HapticFeedback.selectionClick();
        // 검색 모드로 전환
        _enterSearchMode();
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
