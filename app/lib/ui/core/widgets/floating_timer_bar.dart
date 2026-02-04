import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/l10n/app_localizations.dart';
import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/core/theme/app_colors.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';

/// Floating Timer Bar with smooth animation
///
/// Layout: [Book Info] <-Spacer-> [Timer] <-Spacer-> [Buttons]
class FloatingTimerBar extends StatefulWidget {
  final bool hasBottomNav;
  final String? currentViewingBookId;

  const FloatingTimerBar({
    super.key,
    this.hasBottomNav = true,
    this.currentViewingBookId,
  });

  @override
  State<FloatingTimerBar> createState() => _FloatingTimerBarState();
}

class _FloatingTimerBarState extends State<FloatingTimerBar>
    with TickerProviderStateMixin {
  bool _isMinimized = false; // Start expanded by default
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;

  // Dynamic minimized width calculated based on content
  double _minimizedWidth = 180.0; // Initial default, will be updated

  // Colors
  static const Color _coral = Color(0xFFE85A5A);
  static const Color _darkBg = Color(0xFF2C2C2E);
  static const Color _surface = Color(0xFF3A3A3C);

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Start expanded (value = 0 means expanded, 1 means minimized)
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

  // Calculate minimized width based on actual content
  double _calculateMinimizedWidth(String timeText, bool hasBook) {
    // Calculate text width using TextPainter
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeText,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textWidth = textPainter.width;

    // Component widths
    final thumbnailWidth =
        hasBook ? 32.0 : 18.0; // 32 for book, 18 for timer icon
    final thumbnailSpacing = 8.0; // Always 8
    final iconWidth = 16.0; // expand icon
    final iconSpacing = 8.0;
    final horizontalPadding = 24.0; // 16 + 8 = 24

    // Total width
    return textWidth +
        thumbnailWidth +
        thumbnailSpacing +
        iconWidth +
        iconSpacing +
        horizontalPadding;
  }

  String _formatDurationShort(Duration duration, BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0) {
      parts.add('${minutes}m');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }

  Future<void> _navigateToBookDetail(String? bookId) async {
    if (bookId == null) return;

    try {
      final bookService = BookService();
      final book = await bookService.getBookById(bookId);
      if (book != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      }
    } catch (e) {
      debugPrint('책 상세 이동 실패: $e');
    }
  }

  void _showStopConfirmation(
      BuildContext context, ReadingTimerViewModel timerVm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final durationText = _formatDurationShort(timerVm.elapsed, context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => Container(
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
              '지금까지 $durationText 동안 독서하셨습니다.',
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
                    onTap: () => Navigator.pop(sheetContext),
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
                      // Save book info before stop() resets them
                      final bookId = timerVm.currentBookId;
                      final savedDurationText =
                          _formatDurationShort(timerVm.elapsed, sheetContext);

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      await timerVm.stop();
                      if (mounted && bookId != null) {
                        _showPageUpdateModal(
                            context, bookId, savedDurationText);
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
      BuildContext context, String bookId, String durationText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController pageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      useRootNavigator: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(sheetContext).viewPadding.bottom,
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
                  '$durationText 독서 완료!',
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
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final pageText = pageController.text.trim();
                    final page = int.tryParse(pageText);
                    if (page == null || page <= 0) {
                      return;
                    }

                    try {
                      final bookService = BookService();
                      await bookService.updateCurrentPage(bookId, page);

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text('$page 페이지로 업데이트되었습니다'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: const Text('페이지 업데이트에 실패했습니다'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '페이지 업데이트',
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
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

        // Get book info from timer ViewModel
        // Hide book info if viewing the same book's detail screen
        final isViewingSameBook = widget.currentViewingBookId != null &&
            widget.currentViewingBookId == timerVm.currentBookId;
        final hasBookInfo =
            timerVm.currentBookTitle != null && !isViewingSameBook;

        // Calculate dynamic minimized width based on current time
        final timeText = _formatDuration(timerVm.elapsed);
        final calculatedWidth = _calculateMinimizedWidth(
          timeText,
          hasBookInfo,
        );
        // Update minimized width if changed (with small threshold to avoid jitter)
        if ((calculatedWidth - _minimizedWidth).abs() > 5.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _minimizedWidth = calculatedWidth;
              });
            }
          });
        }

        return AnimatedBuilder(
          animation: _expandController,
          builder: (context, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final expandedWidth = screenWidth - 32;

            // Calculate width: when animation is 0 = expanded, 1 = minimized
            final currentWidth = expandedWidth -
                ((expandedWidth - _minimizedWidth) * _widthAnimation.value);

            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  bottom: widget.hasBottomNav ? 90 : 16,
                ),
                child: GestureDetector(
                  onTap: _isMinimized ? _toggleExpand : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    width: currentWidth,
                    height: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
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
                              ? _buildMinimizedView(
                                  isDark, timerVm, hasBookInfo)
                              : _buildExpandedView(
                                  isDark, timerVm, hasBookInfo),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimizedView(
      bool isDark, ReadingTimerViewModel timerVm, bool hasBookInfo) {
    final imageUrl = timerVm.currentBookImageUrl;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book thumbnail (left side) - same size as expanded view
          if (hasBookInfo)
            Container(
              width: 32,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              child: imageUrl == null
                  ? Icon(
                      CupertinoIcons.book,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      size: 16,
                    )
                  : null,
            ),
          if (!hasBookInfo)
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
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          // Expand icon (right side)
          GestureDetector(
            onTap: _toggleExpand,
            child: Icon(
              CupertinoIcons.arrow_up_left_arrow_down_right,
              color: isDark ? Colors.white54 : Colors.black45,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(
      bool isDark, ReadingTimerViewModel timerVm, bool hasBookInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Book thumbnail + title (left side, tappable to navigate)
          if (hasBookInfo)
            _BookInfoButton(
              title: timerVm.currentBookTitle!,
              imageUrl: timerVm.currentBookImageUrl,
              isDark: isDark,
              onTap: () => _navigateToBookDetail(timerVm.currentBookId),
            ),
          // No spacer when no book info - timer starts from left
          if (!hasBookInfo) const SizedBox(width: 8),

          // Spacer to push timer to center
          const Spacer(),

          // Timer display (center)
          Text(
            _formatDuration(timerVm.elapsed),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          // Spacer to push buttons to right
          const Spacer(),

          // Buttons (right side)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  width: 40,
                  height: 40,
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
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Stop button
              GestureDetector(
                onTap: () => _showStopConfirmation(context, timerVm),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.stop_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Collapse button (minimize icon)
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
                    CupertinoIcons.arrow_down_right_arrow_up_left,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Book info display widget with thumbnail and title
class _BookInfoButton extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isDark;
  final VoidCallback? onTap;

  const _BookInfoButton({
    required this.title,
    this.imageUrl,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              child: imageUrl == null
                  ? Icon(
                      CupertinoIcons.book,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // Book title (4 chars max with ellipsis)
            Text(
              title.length > 4 ? '${title.substring(0, 4)}...' : title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
