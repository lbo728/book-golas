import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';
import 'package:book_golas/domain/models/book.dart';

/// Floating timer bar with minimize/expand, Liquid Glass style, and navigation
class FloatingTimerBar extends StatefulWidget {
  final bool hasBottomNav;
  final Book? currentBook;
  final VoidCallback? onNavigateToBookDetail;

  const FloatingTimerBar({
    super.key,
    this.hasBottomNav = true,
    this.currentBook,
    this.onNavigateToBookDetail,
  });

  @override
  State<FloatingTimerBar> createState() => _FloatingTimerBarState();
}

class _FloatingTimerBarState extends State<FloatingTimerBar>
    with SingleTickerProviderStateMixin {
  bool _isMinimized = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
      if (_isMinimized) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showStopConfirmation(
      BuildContext context, ReadingTimerViewModel timerVm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              CupertinoIcons.stop_circle_fill,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              '독서를 종료하시겠어요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '지금까지 ${_formatDurationShort(timerVm.elapsed)} 동안 독서하셨습니다.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '계속하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await timerVm.stop();
                      if (context.mounted) {
                        _showPageUpdateModal(context, timerVm);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.destructive,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '종료하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPageUpdateModal(
      BuildContext context, ReadingTimerViewModel timerVm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController pageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatDurationShort(timerVm.elapsed)}의 독서가 기록되었습니다!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '어디까지 읽었는지 기록해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현재까지 읽은 페이지를 입력하면 진행률이 업데이트됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '페이지 번호',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  suffixText: '페이지',
                  suffixStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // TODO: Save page update
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '기록하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '나중에 하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ReadingTimerViewModel>(
      builder: (context, timerVm, child) {
        if (!timerVm.isRunning && !timerVm.isPaused) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom: widget.hasBottomNav ? 90 : 16,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return GestureDetector(
                onTap: _isMinimized ? _toggleMinimize : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 62,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: _isMinimized
                          ? _buildMinimizedView(isDark, timerVm)
                          : _buildExpandedView(isDark, timerVm),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMinimizedView(bool isDark, ReadingTimerViewModel timerVm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _formatDuration(timerVm.elapsed),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        // Expand button
        GestureDetector(
          onTap: _toggleMinimize,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chevron_left,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(bool isDark, ReadingTimerViewModel timerVm) {
    return Row(
      children: [
        // Minimize button
        GestureDetector(
          onTap: _toggleMinimize,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Pause/Resume button
        GestureDetector(
          onTap: () {
            if (timerVm.isRunning) {
              timerVm.pause();
            } else {
              timerVm.resume();
            }
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              timerVm.isRunning
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Stop button
        GestureDetector(
          onTap: () => _showStopConfirmation(context, timerVm),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.stop_fill,
              color: AppColors.destructive,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Timer display
        Expanded(
          child: Text(
            _formatDuration(timerVm.elapsed),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        // Navigate to book detail button
        if (widget.onNavigateToBookDetail != null)
          GestureDetector(
            onTap: widget.onNavigateToBookDetail,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.book_fill,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
