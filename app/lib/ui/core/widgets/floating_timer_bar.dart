import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/ui/book_list/view_model/book_list_view_model.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/domain/models/book.dart';

/// Floating Timer Bar with smooth animation
///
/// Layout: [Book Info] <-Spacer-> [Timer] <-Spacer-> [Buttons]
class FloatingTimerBar extends StatefulWidget {
  final bool hasBottomNav;

  const FloatingTimerBar({
    super.key,
    this.hasBottomNav = true,
  });

  @override
  State<FloatingTimerBar> createState() => _FloatingTimerBarState();
}

class _FloatingTimerBarState extends State<FloatingTimerBar>
    with TickerProviderStateMixin {
  bool _isMinimized = false; // Start expanded by default
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;

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

  String _formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Book? _findBookById(String? bookId, List<Book> books) {
    if (bookId == null) return null;
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  void _navigateToBookDetail(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
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

    return Consumer2<ReadingTimerViewModel, BookListViewModel>(
      builder: (context, timerVm, bookListVm, child) {
        if (!timerVm.isRunning && !timerVm.isPaused) {
          return const SizedBox.shrink();
        }

        // Get current book from timer's bookId
        final currentBook =
            _findBookById(timerVm.currentBookId, bookListVm.books);

        return AnimatedBuilder(
          animation: _expandController,
          builder: (context, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final expandedWidth = screenWidth - 32;
            final minimizedWidth = 120.0;

            // Calculate width: when animation is 0 = expanded, 1 = minimized
            final currentWidth = expandedWidth -
                ((expandedWidth - minimizedWidth) * _widthAnimation.value);

            return Positioned(
              left: 16,
              right: _isMinimized ? null : 16,
              bottom: widget.hasBottomNav ? 90 : 16,
              child: GestureDetector(
                onTap: _isMinimized ? _toggleExpand : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  width: _isMinimized ? null : currentWidth,
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
                        child: IntrinsicWidth(
                          child: _isMinimized
                              ? _buildMinimizedView(
                                  isDark, timerVm, currentBook)
                              : _buildExpandedView(
                                  isDark, timerVm, currentBook),
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
      bool isDark, ReadingTimerViewModel timerVm, Book? book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book thumbnail (left side)
          if (book != null)
            Container(
              width: 28,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
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
                      size: 14,
                    )
                  : null,
            ),
          if (book == null)
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
      bool isDark, ReadingTimerViewModel timerVm, Book? book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Book thumbnail + title (tappable with feedback, left side)
          if (book != null)
            _BookInfoButton(
              book: book,
              isDark: isDark,
              onTap: () => _navigateToBookDetail(context, book),
            ),
          if (book == null) const SizedBox(width: 40),

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
                  width: 28,
                  height: 28,
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
                    size: 12,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Stop button
              GestureDetector(
                onTap: () => _showStopConfirmation(context, timerVm),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.stop_fill,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Collapse button (minimize icon)
              GestureDetector(
                onTap: _toggleExpand,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_down_right_arrow_up_left,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 12,
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

/// Book info button with press feedback and haptic
/// Long press: navigate only if released within widget bounds
class _BookInfoButton extends StatefulWidget {
  final Book book;
  final bool isDark;
  final VoidCallback onTap;

  const _BookInfoButton({
    required this.book,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BookInfoButton> createState() => _BookInfoButtonState();
}

class _BookInfoButtonState extends State<_BookInfoButton> {
  bool _isPressed = false;
  final GlobalKey _key = GlobalKey();
  Offset? _pressPosition;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressPosition = details.globalPosition;
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isPressed = true);
    _pressPosition = details.globalPosition;
    HapticFeedback.mediumImpact();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isPressed = false);

    // Check if release is within widget bounds
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final releasePosition = details.globalPosition;

      // Check if release is within the widget
      if (releasePosition.dx >= position.dx &&
          releasePosition.dx <= position.dx + size.width &&
          releasePosition.dy >= position.dy &&
          releasePosition.dy <= position.dy + size.height) {
        // Released within widget - navigate
        widget.onTap();
      }
    }
  }

  void _handleLongPressCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
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
                image: widget.book.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.book.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              child: widget.book.imageUrl == null
                  ? Icon(
                      CupertinoIcons.book,
                      color:
                          widget.isDark ? Colors.grey[600] : Colors.grey[500],
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // Book title (4 chars max with ellipsis)
            Text(
              widget.book.title.length > 4
                  ? '${widget.book.title.substring(0, 4)}...'
                  : widget.book.title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
