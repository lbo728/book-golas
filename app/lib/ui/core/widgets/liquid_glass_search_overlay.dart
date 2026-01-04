import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HIG 검색 필드 오버레이 (초점을 맞춘 상태)
///
/// HIG_LIQUID_GLASS.md 참조:
/// "검색 필드에 초점을 맞춘 상태로 시작하면 키보드가 즉시 나타나고
/// 그 위에 검색 필드가 표시되어 바로 검색을 시작할 수 있습니다."
class LiquidGlassSearchOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final ValueChanged<String> onSearch;
  final String? initialQuery;

  const LiquidGlassSearchOverlay({
    super.key,
    required this.onDismiss,
    required this.onSearch,
    this.initialQuery,
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
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // HIG: 초점을 맞춘 상태로 시작 (키보드 즉시 표시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // 반투명 배경 (탭하면 닫힘)
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
              ),
            ),
            // 검색 필드 (키보드 위에 표시)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding + 20 + _slideAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildSearchField(isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(bool isDark) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: hintColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '책 제목, 저자 검색',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {});
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: hintColor,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _dismiss,
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.activeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
  String? initialQuery,
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
      initialQuery: initialQuery,
    ),
  );

  Overlay.of(context).insert(entry);
}
