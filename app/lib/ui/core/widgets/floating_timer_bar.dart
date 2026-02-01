import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/domain/models/book.dart';

/// Cozy Reading Timer Bar - Warm, friendly, and delightful
///
/// Design Philosophy:
/// - Soft, organic shapes (all circular buttons)
/// - Warm color palette (coral, mint, cream)
/// - Smooth, playful animations
/// - Consistent 48px button sizing
/// - Enhanced Liquid Glass blur effects
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
    with TickerProviderStateMixin {
  bool _isMinimized = false;
  late AnimationController _expandController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Cozy Color Palette
  static const Color _coral = Color(0xFFFF6B6B);
  static const Color _mint = Color(0xFF4ECDC4);
  static const Color _cream = Color(0xFFFFF3E0);
  static const Color _warmDark = Color(0xFF2D2D2D);
  static const Color _surface = Color(0xFF3D3D3D);

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
      if (_isMinimized) {
        _expandController.forward();
      } else {
        _expandController.reverse();
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
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? _warmDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Icon with soft background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _coral.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.heart_fill,
                size: 32,
                color: _coral,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              '독서를 마치시겠어요?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // Time info with warm styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? _surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '지금까지 ${_formatDurationShort(timerVm.elapsed)} 동안\n멋진 독서를 하셨습니다 📚',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _buildSoftButton(
                    label: '계속하기',
                    onTap: () => Navigator.pop(context),
                    isSecondary: true,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSoftButton(
                    label: '종료하기',
                    onTap: () async {
                      Navigator.pop(context);
                      await timerVm.stop();
                      if (context.mounted) {
                        _showPageUpdateModal(context, timerVm);
                      }
                    },
                    isSecondary: false,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftButton({
    required String label,
    required VoidCallback onTap,
    required bool isSecondary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? (isDark ? _surface : Colors.grey[200]) : _coral,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSecondary
              ? null
              : [
                  BoxShadow(
                    color: _coral.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSecondary
                ? (isDark ? Colors.white : Colors.black)
                : Colors.white,
          ),
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
            color: isDark ? _warmDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),

              // Success badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: _mint,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDurationShort(timerVm.elapsed)} 독서 완료!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '어디까지 읽었는지 기록해주세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현재까지 읽은 페이지를 입력하면\n진행률이 업데이트됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Page input with cozy styling
              Container(
                decoration: BoxDecoration(
                  color: isDark ? _surface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: pageController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    suffixText: '페이지',
                    suffixStyle: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Primary button
              GestureDetector(
                onTap: () {
                  // TODO: Save page update
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _coral,
                        _coral.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _coral.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    '기록하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '나중에 하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
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
          bottom: widget.hasBottomNav ? 100 : 20,
          child: AnimatedBuilder(
            animation: Listenable.merge([_expandController, _pulseController]),
            builder: (context, child) {
              return GestureDetector(
                onTap: _isMinimized ? _toggleMinimize : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            isDark
                                ? _surface.withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.95),
                            isDark
                                ? _warmDark.withValues(alpha: 0.9)
                                : _cream.withValues(alpha: 0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          // Soft outer glow when running
                          if (timerVm.isRunning)
                            BoxShadow(
                              color: _coral.withValues(
                                alpha: 0.3 + (_pulseAnimation.value * 0.2),
                              ),
                              blurRadius: 20 + (_pulseAnimation.value * 10),
                              spreadRadius: 2 + (_pulseAnimation.value * 2),
                            ),
                          // Base shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer icon with pulse
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: timerVm.isRunning
                ? _coral.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            timerVm.isRunning
                ? CupertinoIcons.timer_fill
                : CupertinoIcons.pause_fill,
            color: timerVm.isRunning
                ? _coral
                : (isDark ? Colors.white70 : Colors.black54),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Time display
        Text(
          _formatDuration(timerVm.elapsed),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),

        // Expand button
        GestureDetector(
          onTap: _toggleMinimize,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chevron_left,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(bool isDark, ReadingTimerViewModel timerVm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Book navigation button
          if (widget.onNavigateToBookDetail != null)
            _buildCircularButton(
              icon: CupertinoIcons.book_fill,
              onTap: widget.onNavigateToBookDetail!,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              iconColor: isDark ? Colors.white70 : Colors.black54,
            ),
          if (widget.onNavigateToBookDetail != null) const SizedBox(width: 8),

          // Pause/Resume button
          _buildCircularButton(
            icon: timerVm.isRunning
                ? CupertinoIcons.pause_fill
                : CupertinoIcons.play_fill,
            onTap: () {
              if (timerVm.isRunning) {
                timerVm.pause();
              } else {
                timerVm.resume();
              }
            },
            backgroundColor: timerVm.isRunning
                ? _coral.withValues(alpha: 0.2)
                : _mint.withValues(alpha: 0.2),
            iconColor: timerVm.isRunning ? _coral : _mint,
            isActive: timerVm.isRunning,
          ),
          const SizedBox(width: 8),

          // Stop button
          _buildCircularButton(
            icon: CupertinoIcons.stop_fill,
            onTap: () => _showStopConfirmation(context, timerVm),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            iconColor: isDark ? Colors.white70 : Colors.black54,
          ),

          const SizedBox(width: 12),

          // Timer display - centered with flex
          Expanded(
            child: Text(
              _formatDuration(timerVm.elapsed),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Minimize button
          _buildCircularButton(
            icon: CupertinoIcons.chevron_right,
            onTap: _toggleMinimize,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            iconColor: isDark ? Colors.white70 : Colors.black54,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
    bool isActive = false,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(
                  color: _coral.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size == 40 ? 16 : 20,
        ),
      ),
    );
  }
}
