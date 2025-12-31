import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloatingActionBar extends StatelessWidget {
  final VoidCallback onUpdatePageTap;
  final VoidCallback onAddMemorablePageTap;

  const FloatingActionBar({
    super.key,
    required this.onUpdatePageTap,
    required this.onAddMemorablePageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildUpdatePageButton(isDark),
            ),
            const SizedBox(width: 10),
            _buildAddButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatePageButton(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onUpdatePageTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.book_fill,
                    size: 17,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '페이지 업데이트',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAddMemorablePageTap,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Icon(
                CupertinoIcons.plus,
                size: 22,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KeyboardDoneButton extends StatelessWidget {
  const KeyboardDoneButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.18 : 0.9),
                      Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.keyboard_chevron_compact_down,
                      size: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF5B7FFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF5B7FFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
