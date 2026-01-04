import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HIG 검색 필드 오버레이
///
/// 애니메이션: 검색 버튼이 좌측으로 미끄러지며 인풋바로 확장
/// 닫기: X 버튼 누르면 우측으로 미끄러지며 검색 버튼으로 축소
class LiquidGlassSearchOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final ValueChanged<String> onSearch;
  final Offset searchButtonPosition;
  final double searchButtonSize;

  const LiquidGlassSearchOverlay({
    super.key,
    required this.onDismiss,
    required this.onSearch,
    required this.searchButtonPosition,
    required this.searchButtonSize,
  });

  @override
  State<LiquidGlassSearchOverlay> createState() =>
      _LiquidGlassSearchOverlayState();
}

class _LiquidGlassSearchOverlayState extends State<LiquidGlassSearchOverlay>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 확장 애니메이션 시작
    _animationController.forward();

    // 애니메이션 완료 후 포커스
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _focusNode.unfocus();
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  void _onSubmit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // 검색바 확장 영역 (좌측 마진 16, 우측에 X버튼 + 간격)
    const expandedLeft = 16.0;
    final expandedWidth = screenWidth - 32 - widget.searchButtonSize - 12;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        // 검색 버튼 위치에서 확장된 위치로 보간
        final currentLeft = lerpDouble(
          widget.searchButtonPosition.dx,
          expandedLeft,
          _expandAnimation.value,
        )!;

        final currentWidth = lerpDouble(
          widget.searchButtonSize,
          expandedWidth,
          _expandAnimation.value,
        )!;

        final currentHeight = lerpDouble(
          widget.searchButtonSize,
          56,
          _expandAnimation.value,
        )!;

        // 배경 오버레이 투명도
        final overlayOpacity = _expandAnimation.value * 0.3;

        return Stack(
          children: [
            // 반투명 배경 (탭하면 닫힘)
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                color: Colors.black.withValues(alpha: overlayOpacity),
              ),
            ),

            // 검색 바 (애니메이션)
            Positioned(
              left: currentLeft,
              bottom: bottomPadding + 20,
              width: currentWidth,
              height: currentHeight,
              child: _buildSearchBar(isDark),
            ),

            // X 닫기 버튼 (고정 위치)
            Positioned(
              right: 16,
              bottom: bottomPadding + 20,
              child: _buildCloseButton(isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Material(
          color: Colors.transparent,
          child: Container(
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
                // 검색 아이콘
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    CupertinoIcons.search,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                // 텍스트 입력 영역
                Expanded(
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                      cursorColor: textColor,
                      decoration: InputDecoration(
                        hintText: '책 제목을 입력해주세요.',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSubmit(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _dismiss();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: widget.searchButtonSize,
            height: widget.searchButtonSize,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: borderColor,
                width: 0.5,
              ),
            ),
            child: Icon(
              CupertinoIcons.xmark,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// 검색 오버레이를 표시하는 헬퍼 함수
void showLiquidGlassSearchOverlay(
  BuildContext context, {
  required ValueChanged<String> onSearch,
  required Offset searchButtonPosition,
  required double searchButtonSize,
}) {
  HapticFeedback.selectionClick();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => LiquidGlassSearchOverlay(
      onDismiss: () {
        entry.remove();
      },
      onSearch: (query) {
        entry.remove();
        onSearch(query);
      },
      searchButtonPosition: searchButtonPosition,
      searchButtonSize: searchButtonSize,
    ),
  );

  Overlay.of(context).insert(entry);
}
