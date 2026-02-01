import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/domain/models/book.dart';

/// Floating Timer Bar - Clean, minimal design
///
/// Two states:
/// - Minimized: Small pill with just icon + time
/// - Expanded: Full bar with book thumbnail, title, time, controls
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
  bool _isMinimized = false; // Start expanded by default
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Colors
  static const Color _coral = Color(0xFFE85A5A);
  static const Color _darkBg = Color(0xFF2C2C2E);
  static const Color _surface = Color(0xFF3A3A3C);

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    // Start minimized
    _expandController.value = 0.0;
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isMinimized = !_isMinimized;
      if (_isMinimized) {
        _expandController.reverse();
      } else {
        _expandController.forward();
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
          color: isDark ? _darkBg : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              CupertinoIcons.stop_circle_fill,
              size: 48,
              color: _coral,
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
                        color: _coral,
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
            color: isDark ? _darkBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatDurationShort(timerVm.elapsed)} 독서 완료!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
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
                '현재까지 읽은 페이지를 입력하면 진행률이 업데이트됩니다',
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
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
                  border: OutlineInputBorder(
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
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _coral,
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
          child: GestureDetector(
            onTap: _isMinimized ? _toggleExpand : null,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? _surface.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: _isMinimized
                          ? _buildMinimizedView(isDark, timerVm)
                          : _buildExpandedView(isDark, timerVm),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimizedView(bool isDark, ReadingTimerViewModel timerVm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer icon
        Icon(
          CupertinoIcons.timer,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 18,
        ),
        const SizedBox(width: 8),
        // Time
        Text(
          _formatDuration(timerVm.elapsed),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(bool isDark, ReadingTimerViewModel timerVm) {
    final book = widget.currentBook;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Book thumbnail
          if (book != null)
            GestureDetector(
              onTap: widget.onNavigateToBookDetail,
              child: Container(
                width: 40,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: book.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(book.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                child: book.imageUrl == null
                    ? Icon(
                        CupertinoIcons.book,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        size: 20,
                      )
                    : null,
              ),
            ),
          if (book != null) const SizedBox(width: 12),

          // Book title (truncated)
          if (book != null)
            Expanded(
              flex: 2,
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          if (book == null) const Spacer(flex: 2),

          const SizedBox(width: 12),

          // Timer display
          Text(
            _formatDuration(timerVm.elapsed),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(width: 12),

          // Pause button
          GestureDetector(
            onTap: () {
              if (timerVm.isRunning) {
                timerVm.pause();
              } else {
                timerVm.resume();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                timerVm.isRunning
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                color: isDark ? Colors.white : Colors.black,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Stop button
          GestureDetector(
            onTap: () => _showStopConfirmation(context, timerVm),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.stop_fill,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Collapse button
          GestureDetector(
            onTap: _toggleExpand,
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
                CupertinoIcons.chevron_down,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
