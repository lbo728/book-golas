import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/data/services/google_vision_ocr_service.dart';
import 'package:book_golas/data/services/image_cache_manager.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/core/widgets/book_image_widget.dart';
import 'package:book_golas/core/widgets/custom_snackbar.dart';
import 'package:book_golas/core/widgets/keyboard_accessory_bar.dart';
import 'package:book_golas/features/book_detail/view_model/book_detail_view_model.dart';
import 'package:book_golas/features/book_detail/view_model/memorable_page_view_model.dart';
import 'package:book_golas/features/book_detail/view_model/reading_progress_view_model.dart';
import 'dialogs/daily_target_dialog.dart';
import 'dialogs/today_goal_sheet.dart';
import 'dialogs/update_page_dialog.dart';
import 'circular_progress_painter.dart';
import 'draggable_dismiss_image.dart';
import 'sticky_tab_bar_delegate.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BookDetailViewModel(
            bookService: BookService(),
            initialBook: book,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MemorablePageViewModel(bookId: book.id!),
        ),
        ChangeNotifierProvider(
          create: (_) => ReadingProgressViewModel(bookId: book.id!),
        ),
      ],
      child: _BookDetailContent(book: book),
    );
  }
}

class _BookDetailContent extends StatefulWidget {
  final Book book;

  const _BookDetailContent({required this.book});

  @override
  State<_BookDetailContent> createState() => _BookDetailContentState();
}

class _BookDetailContentState extends State<_BookDetailContent>
    with TickerProviderStateMixin {
  final BookService _bookService = BookService();
  late Book _currentBook;
  int? _todayStartPage;
  int? _todayTargetPage;
  late TabController _tabController;
  late int _attemptCount;
  Map<String, bool> _dailyAchievements = {};

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  int _animatedCurrentPage = 0;
  double _animatedProgress = 0.0;

  final ScrollController _scrollController = ScrollController();

  late Future<List<Map<String, dynamic>>> _bookImagesFuture;
  late Future<List<Map<String, dynamic>>> _progressHistoryFuture;

  List<Map<String, dynamic>>? _cachedImages;

  final Map<String, String> _editedTexts = {};

  bool _isSelectionMode = false;
  final Set<String> _selectedImageIds = {};

  String _memorableSortMode = 'page_desc';

  Uint8List? _pendingImageBytes;
  String _pendingExtractedText = '';
  int? _pendingPageNumber;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _attemptCount = widget.book.attemptCount;
    _todayStartPage = _currentBook.startDate.day;
    _todayTargetPage = _currentBook.targetDate.day;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadDailyAchievements();

    _animatedCurrentPage = _currentBook.currentPage;
    _animatedProgress = _currentBook.currentPage / _currentBook.totalPages;
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.elasticOut,
    );

    _bookImagesFuture = fetchBookImages(_currentBook.id!);
    _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAchievements() async {
    final achievements = <String, bool>{};
    final startDate = _currentBook.startDate;
    final now = DateTime.now();

    for (var i = 0; i < now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      achievements[dateKey] = i % 3 != 1;
    }

    setState(() {
      _dailyAchievements = achievements;
    });
  }

  int get _daysLeft {
    final now = DateTime.now();
    final target = _currentBook.targetDate;
    final days = target.difference(now).inDays;
    return days >= 0 ? days + 1 : days;
  }

  double get _progressPercentage {
    if (_currentBook.totalPages == 0) return 0;
    return (_currentBook.currentPage / _currentBook.totalPages * 100)
        .clamp(0, 100);
  }

  int get _pagesLeft => (_currentBook.totalPages - _currentBook.currentPage)
      .clamp(0, _currentBook.totalPages);

  String get _attemptEncouragement {
    switch (_attemptCount) {
      case 1:
        return '최고!';
      case 2:
        return '잘하고 있다';
      case 3:
        return '화이팅!';
      default:
        return '내가 더 도와줄게...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '독서 상세',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactBookHeader(isDark),
                          const SizedBox(height: 10),

                          _buildCompactReadingSchedule(isDark),
                          const SizedBox(height: 12),

                          _buildDashboardProgress(isDark),
                          const SizedBox(height: 12),

                          _buildCompactStreakRow(isDark),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyTabBarDelegate(
                      child: _buildTabBarOnly(isDark),
                      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMemorablePagesTab(isDark),
                    _buildProgressHistoryTab(isDark),
                    _buildDetailTab(isDark),
                  ],
                ),
              ),
            ),
          ),
          if (isKeyboardOpen)
            _buildKeyboardDoneButton(isDark)
          else
            _buildLiquidGlassFloatingBar(isDark),
        ],
      ),
    );
  }

  Widget _buildCompactReadingSchedule(bool isDark) {
    final startDateStr = _currentBook.startDate
        .toString()
        .substring(0, 10)
        .replaceAll('-', '.');
    final targetDateStr = _currentBook.targetDate
        .toString()
        .substring(0, 10)
        .replaceAll('-', '.');
    final totalDays =
        _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '시작일',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                startDateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(
            CupertinoIcons.arrow_right,
            size: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '목표일',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                targetDateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '($totalDays일)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          if (_attemptCount > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_attemptCount번째',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _showUpdateTargetDateDialogWithConfirm,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                size: 16,
                color: Color(0xFF5B7FFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingScheduleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B7FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: Color(0xFF5B7FFF),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '독서 일정',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleRow(
            '시작일',
            _currentBook.startDate
                .toString()
                .substring(0, 10)
                .replaceAll('-', '.'),
            CupertinoIcons.play_circle,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.flag_fill,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '목표일',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _currentBook.targetDate
                          .toString()
                          .substring(0, 10)
                          .replaceAll('-', '.'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_attemptCount > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_attemptCount번째 · $_attemptEncouragement',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: _showUpdateTargetDateDialogWithConfirm,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value, IconData icon,
      {Widget? trailing, bool isDark = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Future<void> _showUpdatePageDialog() async {
    await UpdatePageDialog.show(
      context: context,
      currentPage: _currentBook.currentPage,
      totalPages: _currentBook.totalPages,
      onUpdate: _updateCurrentPage,
    );
  }

  Future<void> _updateCurrentPage(int newPage) async {
    final oldPage = _currentBook.currentPage;
    final oldProgress = oldPage / _currentBook.totalPages;
    final newProgress = newPage / _currentBook.totalPages;

    try {
      final updatedBook =
          await _bookService.updateCurrentPage(_currentBook.id!, newPage);
      if (updatedBook != null) {
        _animateProgress(oldPage, newPage, oldProgress, newProgress);

        setState(() {
          _currentBook = updatedBook;
          _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
        });

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );

        if (mounted) {
          final pagesRead = newPage - oldPage;
          CustomSnackbar.show(
            context,
            message: '+$pagesRead 페이지! ${newPage}p 도달',
            type: SnackbarType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '오류가 발생했습니다',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _animateProgress(int fromPage, int toPage, double fromProgress, double toProgress) {
    _progressAnimController.reset();

    final pageAnimation = IntTween(begin: fromPage, end: toPage).animate(_progressAnimation);
    final progressTween = Tween<double>(begin: fromProgress, end: toProgress).animate(_progressAnimation);

    void listener() {
      setState(() {
        _animatedCurrentPage = pageAnimation.value;
        _animatedProgress = progressTween.value;
      });
    }

    _progressAnimation.addListener(listener);
    _progressAnimController.forward().then((_) {
      _progressAnimation.removeListener(listener);
      setState(() {
        _animatedCurrentPage = toPage;
        _animatedProgress = toProgress;
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchBookImages(String bookId) async {
    final response = await Supabase.instance.client
        .from('book_images')
        .select('id, image_url, extracted_text, page_number, created_at')
        .eq('book_id', bookId);

    final images = (response as List)
        .map((e) => {
              'id': e['id'] as String,
              'image_url': e['image_url'] as String?,
              'extracted_text': e['extracted_text'] as String?,
              'page_number': e['page_number'] as int?,
              'created_at': e['created_at'] as String,
            })
        .toList();

    images.sort((a, b) {
      final pageA = a['page_number'] as int?;
      final pageB = b['page_number'] as int?;

      if (pageA != null && pageB == null) return -1;
      if (pageA == null && pageB != null) return 1;
      if (pageA != null && pageB != null) {
        final pageCompare = pageB.compareTo(pageA);
        if (pageCompare != 0) return pageCompare;
      }

      final dateA = a['created_at'] as String;
      final dateB = b['created_at'] as String;
      return dateB.compareTo(dateA);
    });

    return images;
  }

  Future<void> _deleteBookImage(String imageId, String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final storage = Supabase.instance.client.storage;
      final bucketPath =
          imageUrl.split('/storage/v1/object/public/book-images/').last;
      await storage.from('book-images').remove([bucketPath]);
    }
    await Supabase.instance.client
        .from('book_images')
        .delete()
        .eq('id', imageId);

    setState(() {
      if (_cachedImages != null) {
        _cachedImages = _cachedImages!.where((img) => img['id'] != imageId).toList();
      }
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedImageIds.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.trash_fill,
                  size: 32,
                  color: Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$count개 항목을 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '삭제한 항목은 복구할 수 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);

                        final idsToDelete = _selectedImageIds.toList();
                        for (final imageId in idsToDelete) {
                          final image = _cachedImages?.firstWhere(
                            (img) => img['id'] == imageId,
                            orElse: () => {},
                          );
                          final imageUrl = image?['image_url'] as String?;
                          await _deleteBookImage(imageId, imageUrl);
                        }

                        setState(() {
                          _selectedImageIds.clear();
                          _isSelectionMode = false;
                        });

                        if (mounted) {
                          CustomSnackbar.show(
                            context,
                            message: '$count개 항목이 삭제되었습니다',
                            type: SnackbarType.success,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteImage(String imageId, String? imageUrl, {bool dismissParentOnDelete = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.trash,
                  size: 32,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 항목을 삭제하면 복구할 수 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(bottomSheetContext);
                        if (dismissParentOnDelete) {
                          Navigator.pop(context);
                        }
                        await _deleteBookImage(imageId, imageUrl);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReplaceImageConfirmation({required VoidCallback onConfirm}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 32,
                  color: Colors.amber[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '이미지를 교체하시겠습니까?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기존에 추출한 텍스트가 사라집니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        onConfirm();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '교체하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageFullscreenOnly(Uint8List imageBytes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissImage(
            animation: animation,
            imageBytes: imageBytes,
          );
        },
      ),
    );
  }

  Future<bool> _uploadAndSaveMemorablePage({
    Uint8List? imageBytes,
    required String extractedText,
    int? pageNumber,
  }) async {
    try {
      String? publicUrl;

      if (imageBytes != null) {
        final fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storage = Supabase.instance.client.storage;
        await storage.from('book-images').uploadBinary(fileName, imageBytes,
            fileOptions: const FileOptions(upsert: true));
        publicUrl = storage.from('book-images').getPublicUrl(fileName);
      }

      final result = await Supabase.instance.client.from('book_images').insert({
        'book_id': _currentBook.id,
        'image_url': publicUrl,
        'caption': '',
        'extracted_text': extractedText.isEmpty ? null : extractedText,
        'page_number': pageNumber,
      }).select().single();

      setState(() {
        if (_cachedImages != null) {
          _cachedImages = [result, ..._cachedImages!];
        }
        _bookImagesFuture = fetchBookImages(_currentBook.id!);
      });

      if (mounted) {
        _tabController.animateTo(0);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        CustomSnackbar.show(
          context,
          message: '인상적인 페이지가 저장되었습니다',
          type: SnackbarType.success,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError = errorMessage.contains('SocketException') ||
            errorMessage.contains('Connection') ||
            errorMessage.contains('timeout');

        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('업로드 실패'),
            content: Text(
              isNetworkError
                  ? '네트워크 연결을 확인해주세요.\n연결 상태가 양호하면 다시 시도해주세요.'
                  : '인상적인 페이지를 저장하는 중 오류가 발생했습니다.\n업로드 버튼을 눌러 다시 시도해주세요.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
      return false;
    }
  }

  void _showAddMemorablePageModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentContext = context;
    Uint8List? fullImageBytes = _pendingImageBytes;
    String extractedText = _pendingExtractedText;
    int? pageNumber = _pendingPageNumber;
    bool isUploading = false;
    String? pageValidationError;
    bool hasShownPageError = false;
    bool isOcrExtracting = false;
    bool hideKeyboardAccessory = false;
    bool uploadSuccess = false;

    final textController = TextEditingController(text: _pendingExtractedText);
    final pageController = TextEditingController(
      text: _pendingPageNumber != null ? _pendingPageNumber.toString() : '',
    );
    final textFocusNode = FocusNode();
    final pageFocusNode = FocusNode();
    final scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = keyboardHeight > 0;

            return GestureDetector(
              onTap: () {
                textFocusNode.unfocus();
                pageFocusNode.unfocus();
              },
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.85 - MediaQuery.of(context).padding.top,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                    children: [
                      SizedBox(height: 12 + MediaQuery.of(context).padding.top),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final hasChanges = fullImageBytes != null ||
                                    textController.text.isNotEmpty ||
                                    pageController.text.isNotEmpty;
                                if (hasChanges) {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (bottomSheetContext) => Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 4,
                                            margin: const EdgeInsets.only(bottom: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[400],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          Text(
                                            '변경 중인 사항이 취소됩니다.\n닫으시겠어요?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => Navigator.pop(bottomSheetContext),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '취소',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.pop(bottomSheetContext);
                                                    Navigator.pop(context);
                                                    _pendingImageBytes = null;
                                                    _pendingExtractedText = '';
                                                    _pendingPageNumber = null;
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[400],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        '닫기',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 8),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 22,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              '기록 추가',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 38),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: fullImageBytes != null
                                    ? GestureDetector(
                                        onTap: () => _showImageFullscreenOnly(fullImageBytes!),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: Image.memory(
                                                fullImageBytes!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final shouldProceed = await showModalBottomSheet<bool>(
                                                    context: context,
                                                    backgroundColor: Colors.transparent,
                                                    builder: (bottomSheetContext) => Container(
                                                      padding: const EdgeInsets.all(20),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 4,
                                                            margin: const EdgeInsets.only(bottom: 20),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[400],
                                                              borderRadius: BorderRadius.circular(2),
                                                            ),
                                                          ),
                                                          Text(
                                                            '텍스트를 추출하시겠어요?',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w500,
                                                              color: isDark ? Colors.white : Colors.black,
                                                              height: 1.5,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            '작성하신 텍스트를 덮어씁니다.\n크레딧을 소모합니다.',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 24),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: GestureDetector(
                                                                  onTap: () => Navigator.pop(bottomSheetContext, false),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    decoration: BoxDecoration(
                                                                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    child: Center(
                                                                      child: Text(
                                                                        '취소',
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: GestureDetector(
                                                                  onTap: () => Navigator.pop(bottomSheetContext, true),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFF5B7FFF),
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    child: const Center(
                                                                      child: Text(
                                                                        '추출하기',
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: Colors.white,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 8),
                                                        ],
                                                      ),
                                                    ),
                                                  );

                                                  if (shouldProceed != true) return;

                                                  _extractTextFromLocalImage(
                                                    fullImageBytes!,
                                                    (ocrText, extractedPageNum) {
                                                      setModalState(() {
                                                        extractedText = ocrText;
                                                        textController.text = ocrText;
                                                        if (extractedPageNum != null) {
                                                          pageNumber = extractedPageNum;
                                                          pageController.text = extractedPageNum.toString();
                                                        }
                                                      });
                                                    },
                                                  );
                                                },
                                                behavior: HitTestBehavior.opaque,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.document_scanner_outlined,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '텍스트 추출',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showReplaceImageConfirmation(
                                                    onConfirm: () {
                                                      _showImageSourceActionSheet(
                                                        onImageSelected: (imageBytes, ocrText, ocrPageNumber) {
                                                          setModalState(() {
                                                            fullImageBytes = imageBytes;
                                                            if (ocrText.isNotEmpty) {
                                                              textController.text = ocrText;
                                                            }
                                                            if (ocrPageNumber != null) {
                                                              pageController.text = ocrPageNumber.toString();
                                                            }
                                                          });
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                behavior: HitTestBehavior.opaque,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        CupertinoIcons.arrow_2_squarepath,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '교체하기',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _showImageSourceActionSheet(
                                          onImageSelected: (imageBytes, ocrText, ocrPageNumber) {
                                            setModalState(() {
                                              fullImageBytes = imageBytes;
                                              if (ocrText.isNotEmpty) {
                                                textController.text = ocrText;
                                              }
                                              if (ocrPageNumber != null) {
                                                pageController.text = ocrPageNumber.toString();
                                              }
                                            });
                                          },
                                        ),
                                        child: Center(
                                          child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.camera,
                                              size: 40,
                                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              '터치하여 이미지 추가',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '(선택사항)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 20),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.book,
                                        size: 16,
                                        color: pageValidationError != null
                                            ? Colors.red[400]
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '페이지 수',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: pageValidationError != null
                                              ? Colors.red[400]
                                              : (isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                      Text(
                                        ' *',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: pageController,
                                          focusNode: pageFocusNode,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: pageValidationError != null
                                                ? Colors.red[400]
                                                : (isDark ? Colors.white : Colors.black),
                                          ),
                                          onChanged: (value) {
                                            if (value.isEmpty) {
                                              setModalState(() {
                                                pageNumber = null;
                                                pageValidationError = null;
                                                hasShownPageError = false;
                                              });
                                              return;
                                            }
                                            final parsed = int.tryParse(value);
                                            if (parsed != null) {
                                              if (parsed > _currentBook.totalPages) {
                                                if (!hasShownPageError) {
                                                  HapticFeedback.heavyImpact();
                                                  CustomSnackbar.show(
                                                    parentContext,
                                                    message: '총 페이지 수(${_currentBook.totalPages})를 초과할 수 없습니다',
                                                    type: SnackbarType.error,
                                                    rootOverlay: true,
                                                    aboveKeyboard: true,
                                                  );
                                                  hasShownPageError = true;
                                                }
                                                setModalState(() {
                                                  pageNumber = parsed;
                                                  pageValidationError = '전체 페이지 수를 초과할 수 없습니다.';
                                                });
                                              } else {
                                                setModalState(() {
                                                  pageNumber = parsed;
                                                  pageValidationError = null;
                                                  hasShownPageError = false;
                                                });
                                              }
                                            }
                                          },
                                          decoration: InputDecoration(
                                            hintText: '',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: pageValidationError != null
                                                    ? Colors.red[400]!
                                                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: pageValidationError != null
                                                    ? Colors.red[400]!
                                                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: pageValidationError != null
                                                    ? Colors.red[400]!
                                                    : const Color(0xFF5B7FFF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pageValidationError != null) ...[
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.doc_text,
                                        size: 16,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '인상적인 문구',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        ' *',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (textController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          textController.clear();
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.trash,
                                            size: 14,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '모두 지우기',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(minHeight: 150),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  controller: textController,
                                  focusNode: textFocusNode,
                                  maxLines: null,
                                  minLines: 6,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  onChanged: (value) {
                                    setModalState(() {});
                                  },
                                  onTap: () {
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (scrollController.hasClients) {
                                        scrollController.animateTo(
                                          scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  },
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '인상적인 대목을 기록해보세요.',
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    if (!isKeyboardOpen && !isUploading)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 32,
                        child: GestureDetector(
                          onTap: textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null
                              ? null
                              : () async {
                                  setModalState(() => isUploading = true);
                                  final success = await _uploadAndSaveMemorablePage(
                                    imageBytes: fullImageBytes,
                                    extractedText: textController.text,
                                    pageNumber: int.tryParse(pageController.text),
                                  );
                                  if (success && mounted) {
                                    uploadSuccess = true;
                                    _pendingImageBytes = null;
                                    _pendingExtractedText = '';
                                    _pendingPageNumber = null;
                                    Navigator.pop(context);
                                  } else {
                                    setModalState(() => isUploading = false);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null
                                  ? (isDark ? Colors.grey[700] : Colors.grey[300])
                                  : const Color(0xFF5B7FFF),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null)
                                      ? Colors.transparent
                                      : const Color(0xFF5B7FFF).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '업로드',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null
                                      ? (isDark ? Colors.grey[500] : Colors.grey[500])
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isKeyboardOpen && (textFocusNode.hasFocus || pageFocusNode.hasFocus) && !hideKeyboardAccessory)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: KeyboardAccessoryBar(
                          isDark: isDark,
                          showNavigation: true,
                          icon: CupertinoIcons.checkmark,
                          onUp: () {
                            if (textFocusNode.hasFocus) {
                              textFocusNode.unfocus();
                              pageFocusNode.requestFocus();
                            }
                          },
                          onDown: () {
                            if (pageFocusNode.hasFocus) {
                              pageFocusNode.unfocus();
                              textFocusNode.requestFocus();
                            }
                          },
                          onDone: () {
                            setModalState(() {
                              hideKeyboardAccessory = true;
                            });
                            textFocusNode.unfocus();
                            pageFocusNode.unfocus();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                setModalState(() {
                                  hideKeyboardAccessory = false;
                                });
                              }
                            });
                          },
                        ),
                      ),
                    if (isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF5B7FFF),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '업로드 중...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            );
          },
        );
      },
    ).then((_) {
      if (!uploadSuccess) {
        _pendingImageBytes = fullImageBytes;
        _pendingExtractedText = textController.text;
        _pendingPageNumber = int.tryParse(pageController.text);
      }
    });
  }

  void _showImageSourceActionSheet({
    required Function(Uint8List imageBytes, String ocrText, int? pageNumber) onImageSelected,
  }) {
    final isCameraAvailable = !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS) &&
        (Platform.isAndroid || (Platform.isIOS && !Platform.isMacOS));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      color: Color(0xFF5B7FFF),
                    ),
                  ),
                  title: Text(
                    '카메라 촬영하기',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: isCameraAvailable && Platform.isIOS
                      ? () async {
                          Navigator.pop(context);
                          await _pickImageAndExtractText(
                            ImageSource.camera,
                            onImageSelected,
                          );
                        }
                      : () {
                          Navigator.pop(context);
                          CustomSnackbar.show(
                            this.context,
                            message: '시뮬레이터에서는 카메라를 사용할 수 없습니다',
                            type: SnackbarType.warning,
                          );
                        },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo_fill,
                      color: Color(0xFF5B7FFF),
                    ),
                  ),
                  title: Text(
                    '라이브러리에서 가져오기',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageAndExtractText(
                      ImageSource.gallery,
                      onImageSelected,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageOnly(
    ImageSource source,
    Function(Uint8List imageBytes) onComplete,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    onComplete(imageBytes);
  }

  Future<void> _extractTextFromLocalImage(
    Uint8List imageBytes,
    Function(String extractedText, int? pageNumber) onComplete,
  ) async {
    bool isLoadingDialogShown = false;
    final parentContext = context;

    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      if (!mounted) return;

      debugPrint('🟡 OCR: 크롭 화면 표시 중...');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        uiSettings: [
          IOSUiSettings(
            title: '텍스트 추출 영역 선택',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
          ),
          AndroidUiSettings(
            toolbarTitle: '텍스트 추출 영역 선택',
            toolbarColor: const Color(0xFF5B7FFF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        ],
      );

      try {
        await tempFile.delete();
      } catch (_) {
      }

      if (croppedFile == null) {
        debugPrint('🟠 OCR: 사용자가 크롭을 취소했습니다.');
        return;
      }

      if (!mounted) return;

      debugPrint('🟡 OCR: 크롭 완료, 텍스트 추출 시작...');
      isLoadingDialogShown = true;
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5B7FFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '텍스트 추출 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(dialogContext).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final ocrService = GoogleVisionOcrService();
      final croppedBytes = await croppedFile.readAsBytes();
      debugPrint('🟡 OCR: 크롭된 이미지 크기: ${croppedBytes.length} bytes');

      final ocrText = await ocrService.extractTextFromBytes(croppedBytes);
      final pageNumber = _extractPageNumber(ocrText ?? '');

      if (!mounted) return;

      if (isLoadingDialogShown) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isLoadingDialogShown = false;
      }

      if (ocrText == null || ocrText.isEmpty) {
        debugPrint('🟠 OCR: 텍스트 추출 결과가 비어있습니다.');
        CustomSnackbar.show(parentContext, message: '텍스트를 추출하지 못했습니다. 다른 영역을 선택해보세요.', rootOverlay: true);
        return;
      }

      debugPrint('🟢 OCR: 텍스트 추출 성공 (길이: ${ocrText.length})');
      onComplete(ocrText, pageNumber);
    } catch (e) {
      debugPrint('🔴 OCR: 예외 발생 - $e');
      if (!mounted) return;

      if (isLoadingDialogShown) {
        try {
          Navigator.of(parentContext, rootNavigator: true).pop();
        } catch (_) {
        }
      }

      CustomSnackbar.show(parentContext, message: '텍스트 추출에 실패했습니다. 다시 시도해주세요.', rootOverlay: true);
    }
  }

  Future<void> _pickImageAndExtractText(
    ImageSource source,
    Function(Uint8List imageBytes, String ocrText, int? pageNumber) onComplete,
  ) async {
    bool isLoadingDialogShown = false;
    final parentContext = context;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final fullImageBytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final isDark = Theme.of(parentContext).brightness == Brightness.dark;
      final shouldExtract = await showModalBottomSheet<bool>(
        context: parentContext,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  Icons.document_scanner_outlined,
                  size: 48,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  '텍스트를 추출하시겠어요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '크레딧이 소모됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                        ),
                        child: Text(
                          '괜찮아요',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7FFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '추출할게요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      );

      if (!mounted) return;

      if (shouldExtract != true) {
        onComplete(fullImageBytes, '', null);
        return;
      }

      debugPrint('🟡 OCR: 크롭 화면 표시 중...');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          IOSUiSettings(
            title: '텍스트 추출 영역 선택',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
          ),
          AndroidUiSettings(
            toolbarTitle: '텍스트 추출 영역 선택',
            toolbarColor: const Color(0xFF5B7FFF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        ],
      );

      if (croppedFile == null) {
        debugPrint('🟠 OCR: 사용자가 크롭을 취소했습니다.');
        return;
      }

      if (!mounted) return;

      debugPrint('🟡 OCR: 크롭 완료, 텍스트 추출 시작...');
      isLoadingDialogShown = true;
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5B7FFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '텍스트 추출 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(dialogContext).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final ocrService = GoogleVisionOcrService();
      final croppedBytes = await croppedFile.readAsBytes();
      debugPrint('🟡 OCR: 크롭된 이미지 크기: ${croppedBytes.length} bytes');

      final ocrText = await ocrService.extractTextFromBytes(croppedBytes);
      final pageNumber = _extractPageNumber(ocrText ?? '');

      if (!mounted) return;

      if (isLoadingDialogShown) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isLoadingDialogShown = false;
      }

      if (ocrText == null || ocrText.isEmpty) {
        debugPrint('🟠 OCR: 텍스트 추출 결과가 비어있습니다.');
        CustomSnackbar.show(parentContext, message: '텍스트를 추출하지 못했습니다. 다른 영역을 선택해보세요.', rootOverlay: true);
        return;
      }

      debugPrint('🟢 OCR: 텍스트 추출 성공 (길이: ${ocrText.length})');
      onComplete(fullImageBytes, ocrText, pageNumber);
    } catch (e) {
      debugPrint('🔴 OCR: 예외 발생 - $e');
      if (!mounted) return;

      if (isLoadingDialogShown) {
        try {
          Navigator.of(parentContext, rootNavigator: true).pop();
        } catch (_) {
        }
      }

      CustomSnackbar.show(parentContext, message: '텍스트 추출에 실패했습니다. 다시 시도해주세요.', rootOverlay: true);
    }
  }

  int? _extractPageNumber(String text) {

    final patterns = [
      RegExp(r'[-–]\s*(\d{1,4})\s*[-–]'),
      RegExp(r'[pP]\.?\s*(\d{1,4})'),
      RegExp(r'[pP]age\s*(\d{1,4})', caseSensitive: false),
      RegExp(r'(\d{1,4})\s*페이지'),
      RegExp(r'(\d{1,4})\s*쪽'),

      RegExp(r'^\s*(\d{1,4})\s*$', multiLine: true),
      RegExp(r'^(\d{1,4})\s+\S', multiLine: true),
      RegExp(r'\S\s+(\d{1,4})$', multiLine: true),

      RegExp(r'\((\d{1,4})\)'),
      RegExp(r'\[(\d{1,4})\]'),

      RegExp(r'^(\d{1,4})\b'),
      RegExp(r'\b(\d{1,4})$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final pageStr = match.group(1);
        if (pageStr != null) {
          final page = int.tryParse(pageStr);
          if (page != null && page > 0 && page < 10000) {
            final matchStart = match.start;
            if (matchStart > 0 && text[matchStart - 1] == '.') {
              continue;
            }
            final matchEnd = match.end;
            if (matchEnd < text.length && text[matchEnd] == '.') {
              continue;
            }
            return page;
          }
        }
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchProgressHistory(String bookId) async {
    final response = await Supabase.instance.client
        .from('reading_progress_history')
        .select('page, created_at')
        .eq('book_id', bookId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => {
              'page': e['page'] as int,
              'created_at': DateTime.parse(e['created_at'] as String),
            })
        .toList();
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHistorySkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 60,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingStateAnalysis(bool isDark, List<Map<String, dynamic>> progressData) {
    final analysisResult = _analyzeReadingState(progressData);
    final emoji = analysisResult['emoji'] as String;
    final title = analysisResult['title'] as String;
    final message = analysisResult['message'] as String;
    final color = analysisResult['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (_attemptCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_attemptCount번째 · $_attemptEncouragement',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analyzeReadingState(List<Map<String, dynamic>> progressData) {
    final progressPercent = _progressPercentage;
    final daysLeft = _daysLeft;
    final totalDays = _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;
    final elapsedDays = DateTime.now().difference(_currentBook.startDate).inDays;
    final readingDays = progressData.length;

    final expectedProgress = elapsedDays > 0
        ? (elapsedDays / totalDays * 100).clamp(0, 100)
        : 0.0;
    final progressDiff = progressPercent - expectedProgress;

    if (progressPercent >= 100) {
      if (_attemptCount > 1) {
        return {
          'emoji': '🏆',
          'title': '드디어 완독!',
          'message': '$_attemptCount번의 도전 끝에 완독에 성공했어요. 포기하지 않은 당신이 멋져요!',
          'color': const Color(0xFF10B981),
        };
      }
      return {
        'emoji': '🎉',
        'title': '완독 축하해요!',
        'message': '목표를 달성했어요. 다음 책도 함께 읽어볼까요?',
        'color': const Color(0xFF10B981),
      };
    }

    if (daysLeft < 0) {
      if (_attemptCount > 1) {
        return {
          'emoji': '💪',
          'title': '이번엔 완주해봐요',
          'message': '$_attemptCount번째 도전이에요. 목표일을 재설정하고 끝까지 읽어볼까요?',
          'color': const Color(0xFFFF6B6B),
        };
      }
      return {
        'emoji': '⏰',
        'title': '목표일이 지났어요',
        'message': '괜찮아요, 새 목표일을 설정하고 다시 시작해봐요!',
        'color': const Color(0xFFFF6B6B),
      };
    }

    if (progressDiff > 20) {
      return {
        'emoji': '🚀',
        'title': '놀라운 속도예요!',
        'message': '예상보다 훨씬 빠르게 읽고 있어요. 이 페이스면 일찍 완독할 수 있겠어요!',
        'color': const Color(0xFF5B7FFF),
      };
    }

    if (progressDiff > 5) {
      return {
        'emoji': '✨',
        'title': '순조롭게 진행 중!',
        'message': '계획보다 앞서가고 있어요. 이대로만 하면 목표 달성 확실해요!',
        'color': const Color(0xFF10B981),
      };
    }

    if (progressDiff > -5) {
      return {
        'emoji': '📖',
        'title': '계획대로 진행 중',
        'message': '꾸준히 읽고 있어요. 오늘도 조금씩 읽어볼까요?',
        'color': const Color(0xFF5B7FFF),
      };
    }

    if (progressDiff > -15) {
      if (_attemptCount > 1) {
        return {
          'emoji': '🔥',
          'title': '조금 더 속도를 내볼까요?',
          'message': '이번에는 꼭 완독해봐요. 매일 조금씩 더 읽으면 따라잡을 수 있어요!',
          'color': const Color(0xFFF59E0B),
        };
      }
      return {
        'emoji': '📚',
        'title': '조금 더 읽어볼까요?',
        'message': '계획보다 살짝 뒤처졌어요. 오늘 조금 더 읽으면 따라잡을 수 있어요!',
        'color': const Color(0xFFF59E0B),
      };
    }

    if (_attemptCount > 1) {
      return {
        'emoji': '💫',
        'title': '포기하지 마세요!',
        'message': '$_attemptCount번째 도전 중이에요. 목표일을 조정하거나 더 집중해서 읽어봐요!',
        'color': const Color(0xFFFF6B6B),
      };
    }
    return {
      'emoji': '📅',
      'title': '목표 재설정이 필요할 수도',
      'message': '현재 페이스로는 목표 달성이 어려워요. 목표일을 조정해볼까요?',
      'color': const Color(0xFFFF6B6B),
    };
  }

  Widget _buildCompactBookHeader(bool isDark) {
    final isCompleted = _currentBook.currentPage >= _currentBook.totalPages &&
        _currentBook.totalPages > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentBook.imageUrl != null &&
                  _currentBook.imageUrl!.isNotEmpty) {
                _showFullScreenImage(
                  'book_cover_compact_${_currentBook.id}',
                  _currentBook.imageUrl!,
                );
              }
            },
            child: Hero(
              tag: 'book_cover_compact_${_currentBook.id}',
              child: Container(
                width: 60,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookImageWidget(
                    imageUrl: _currentBook.imageUrl,
                    iconSize: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _currentBook.title.length > 20
                      ? () => _showFullTitleDialog(_currentBook.title)
                      : null,
                  child: Text(
                    _currentBook.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_currentBook.author != null) ...[
                      Flexible(
                        child: Text(
                          _currentBook.author!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFF5B7FFF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCompleted ? '✓ 완독' : '● 독서 중',
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF5B7FFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardProgress(bool isDark) {
    final progressPercent = (_animatedProgress * 100).toStringAsFixed(0);
    final isOverdue = _daysLeft < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: CircularProgressPainter(
                            progress: _animatedProgress.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFEEF2FF),
                            progressColor: const Color(0xFF5B7FFF),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentBook.currentPage} / ${_currentBook.totalPages}p',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 100,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  isOverdue ? 'D+${_daysLeft.abs()}' : 'D-$_daysLeft',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isOverdue || _daysLeft <= 3
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF5B7FFF),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_pagesLeft페이지',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      TextSpan(
                        text: ' 남았어요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final dailyTarget = _currentBook.dailyTargetPages ??
                        (_daysLeft > 0 ? (_pagesLeft / _daysLeft).ceil() : _pagesLeft);
                    if (dailyTarget > 0) {
                      return GestureDetector(
                        onTap: _showDailyTargetChangeDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '오늘 목표: ${dailyTarget}p',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                CupertinoIcons.pencil,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardDoneButton(bool isDark) {
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

  Widget _buildLiquidGlassFloatingBar(bool isDark) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showUpdatePageDialog,
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
              ),
            ),

            const SizedBox(width: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddMemorablePageModal,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingScheduleCard(isDark),
          const SizedBox(height: 16),

          _buildTodayGoalCardWithStamps(isDark),
        ],
      ),
    );
  }

  Widget _buildCompactStreakRow(bool isDark) {
    const dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    final now = DateTime.now();
    final recentDays = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isAchieved = _dailyAchievements[dateKey] == true;
      final isToday = i == 0;
      recentDays.add({
        'achieved': isAchieved,
        'dayLabel': dayLabels[date.weekday % 7],
        'isToday': isToday,
      });
    }

    int streak = 0;
    for (int i = recentDays.length - 1; i >= 0; i--) {
      if (recentDays[i]['achieved'] == true) {
        streak++;
      } else {
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final dayInfo = recentDays[index];
              final isAchieved = dayInfo['achieved'] as bool;
              final dayLabel = dayInfo['dayLabel'] as String;
              final isToday = dayInfo['isToday'] as bool;
              return Container(
                width: 38,
                margin: EdgeInsets.only(left: index > 0 ? 6 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF5B7FFF)
                            : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isAchieved
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.grey[200]),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF5B7FFF),
                                width: 2,
                              )
                            : null,
                      ),
                      child: isAchieved
                          ? const Icon(
                              CupertinoIcons.checkmark,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.flame_fill,
                size: 16,
                color: streak > 0
                    ? const Color(0xFFF97316)
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
              const SizedBox(width: 4),
              Text(
                streak > 0 ? '$streak일 연속 달성!' : '오늘 첫 기록을 남겨보세요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: streak > 0
                      ? (isDark ? Colors.white : Colors.grey[800])
                      : (isDark ? Colors.grey[400] : Colors.grey[500]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayGoalCardWithStamps(bool isDark) {
    final totalDays =
        _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;
    final now = DateTime.now();
    final todayIndex = now.difference(_currentBook.startDate).inDays;

    int achievedCount = 0;
    int passedDays = 0;
    for (int i = 0; i < totalDays && i <= todayIndex; i++) {
      final date = _currentBook.startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (_dailyAchievements[dateKey] == true) achievedCount++;
      passedDays++;
    }
    final achievementRate =
        passedDays > 0 ? (achievedCount / passedDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '목표 달성 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$passedDays일 중 $achievedCount일 달성',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: achievementRate >= 80
                      ? const Color(0xFFD1FAE5)
                      : achievementRate >= 50
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      achievementRate >= 80
                          ? CupertinoIcons.star_fill
                          : achievementRate >= 50
                              ? CupertinoIcons.hand_thumbsup_fill
                              : CupertinoIcons.flame_fill,
                      size: 14,
                      color: achievementRate >= 80
                          ? const Color(0xFF059669)
                          : achievementRate >= 50
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$achievementRate%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: achievementRate >= 80
                            ? const Color(0xFF059669)
                            : achievementRate >= 50
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = 28.0;
              final spacing = 4.0;
              final columns =
                  ((constraints.maxWidth + spacing) / (cellSize + spacing))
                      .floor();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(totalDays, (index) {
                  final date =
                      _currentBook.startDate.add(Duration(days: index));
                  final dateKey =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final isFuture =
                      date.isAfter(DateTime(now.year, now.month, now.day));
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  final isAchieved = _dailyAchievements[dateKey];

                  Color cellColor;
                  if (isFuture) {
                    cellColor = isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF3F4F6);
                  } else if (isAchieved == true) {
                    cellColor = const Color(0xFF10B981);
                  } else if (isAchieved == false) {
                    cellColor = const Color(0xFFFCA5A5);
                  } else {
                    cellColor = isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE5E7EB);
                  }

                  return Tooltip(
                    message:
                        '${date.month}/${date.day} (Day ${index + 1})${isAchieved == true ? ' ✓' : isAchieved == false ? ' ✗' : ''}',
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF5B7FFF),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isToday
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5B7FFF),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('달성', const Color(0xFF10B981), isDark),
              const SizedBox(width: 16),
              _buildLegendItem('미달성', const Color(0xFFFCA5A5), isDark),
              const SizedBox(width: 16),
              _buildLegendItem('예정', isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarOnly(bool isDark) {
    final tabLabels = ['인상적인 페이지', '히스토리', '상세'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      tabLabels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _tabController.index == index
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _tabController.index == index
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                final indicatorWidth = tabWidth * 0.5;
                return AnimatedBuilder(
                  animation: _tabController.animation!,
                  builder: (context, child) {
                    final animValue = _tabController.animation!.value;
                    final centerPosition = tabWidth * animValue + (tabWidth - indicatorWidth) / 2;
                    return Stack(
                      children: [
                        Positioned(
                          left: centerPosition,
                          child: Container(
                            width: indicatorWidth,
                            height: 2,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showReplaceImageOptionsOverModal({
    required String imageId,
    required String currentText,
    required Function(String? newImageUrl) onReplaced,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
              const SizedBox(height: 20),
              Text(
                '이미지 교체',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera,
                    color: Color(0xFF5B7FFF),
                  ),
                ),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImageOnly(
                    ImageSource.camera,
                    (imageBytes) async {
                      final newUrl = await _replaceImage(imageId, imageBytes, currentText, null);
                      onReplaced(newUrl);
                    },
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.photo,
                    color: Color(0xFF10B981),
                  ),
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImageOnly(
                    ImageSource.gallery,
                    (imageBytes) async {
                      final newUrl = await _replaceImage(imageId, imageBytes, currentText, null);
                      onReplaced(newUrl);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReExtractConfirmation({
    required String imageUrl,
    required Function(String extractedText) onConfirm,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldProceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '텍스트를 추출하시겠어요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '작성하신 텍스트를 덮어씁니다.\n크레딧을 소모합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(bottomSheetContext, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(bottomSheetContext, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B7FFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '추출하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (shouldProceed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5B7FFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '이미지 불러오는 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        uiSettings: [
          IOSUiSettings(
            title: '텍스트 추출 영역 선택',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
          ),
          AndroidUiSettings(
            toolbarTitle: '텍스트 추출 영역 선택',
            toolbarColor: const Color(0xFF5B7FFF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        ],
      );

      await tempFile.delete();

      if (croppedFile == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5B7FFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '텍스트 추출 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final ocrService = GoogleVisionOcrService();
      final croppedBytes = await croppedFile.readAsBytes();
      final ocrText = await ocrService.extractTextFromBytes(croppedBytes) ?? '';

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      onConfirm(ocrText);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      CustomSnackbar.show(context, message: '텍스트 다시 추출에 실패했습니다.', rootOverlay: true);
    }
  }

  Future<String?> _replaceImage(String imageId, Uint8List imageBytes, String extractedText, int? pageNumber) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentBook.id}.jpg';
      final storagePath = 'book_images/$fileName';

      await Supabase.instance.client.storage
          .from('book-images')
          .uploadBinary(storagePath, imageBytes);

      final imageUrl = Supabase.instance.client.storage
          .from('book-images')
          .getPublicUrl(storagePath);

      await Supabase.instance.client.from('book_images').update({
        'image_url': imageUrl,
        'extracted_text': extractedText,
        'page_number': pageNumber,
      }).eq('id', imageId);

      _bookImagesFuture = fetchBookImages(_currentBook.id!);
      setState(() {});

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '이미지가 교체되었습니다',
          type: SnackbarType.success,
        );
      }
      return imageUrl;
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '이미지 교체 실패',
          type: SnackbarType.error,
        );
      }
      return null;
    }
  }

  void _showFullScreenImage(String imageId, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissNetworkImage(
            animation: animation,
            imageUrl: imageUrl,
            imageId: imageId,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showExistingImageModal(
    String imageId,
    String? initialImageUrl,
    String? extractedText, {
    int? pageNumber,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentContext = context;
    final cachedText = _editedTexts[imageId] ?? extractedText ?? '';
    final originalText = cachedText;
    final textController = TextEditingController(text: cachedText);
    final focusNode = FocusNode();
    final pageNumberFocusNode = FocusNode();
    bool isEditing = false;
    bool isSaving = false;
    bool hideKeyboardAccessory = false;
    String? imageUrl = initialImageUrl;
    int? editingPageNumber = pageNumber;
    final pageNumberController = TextEditingController(text: pageNumber?.toString() ?? '');
    bool pageNumberError = false;
    final totalPages = _currentBook.totalPages;
    bool hasShownPageError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool listenerAdded = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!listenerAdded) {
              listenerAdded = true;
              focusNode.addListener(() {
                setModalState(() {});
              });
              pageNumberFocusNode.addListener(() {
                setModalState(() {});
              });
            }

            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = keyboardHeight > 0;
            final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

            final statusBarHeight = MediaQuery.of(context).padding.top;
            final screenHeight = MediaQuery.of(context).size.height;
            final defaultModalHeight = screenHeight * 0.85;
            final availableHeight = screenHeight - statusBarHeight - keyboardHeight;
            final modalHeight = isKeyboardOpen
                ? availableHeight.clamp(0.0, defaultModalHeight)
                : defaultModalHeight;

            void showCancelConfirmation() {
              final hasTextChanges = textController.text != originalText;
              final hasPageChanges = editingPageNumber != pageNumber;
              if (hasTextChanges || hasPageChanges) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (bottomSheetContext) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          '수정 중인 내용이 있습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(bottomSheetContext);
                                  setModalState(() {
                                    textController.text = originalText;
                                    editingPageNumber = pageNumber;
                                    pageNumberController.text = pageNumber?.toString() ?? '';
                                    isEditing = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '변경사항 무시',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(bottomSheetContext),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B7FFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '이어서 하기',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 8),
                      ],
                    ),
                  ),
                );
              } else {
                setModalState(() {
                  isEditing = false;
                });
              }
            }

            return PopScope(
              canPop: !isEditing,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && isEditing) {
                  showCancelConfirmation();
                }
              },
              child: GestureDetector(
              onTap: () {
                if (isEditing) {
                  focusNode.unfocus();
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: keyboardHeight,
                  top: statusBarHeight,
                ),
                child: Stack(
                  children: [
                    Container(
                      height: modalHeight,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                    children: [
                      const SizedBox(height: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                            final hasTextChanges = textController.text != originalText;
                            final hasPageChanges = editingPageNumber != pageNumber;
                            if (isEditing && (hasTextChanges || hasPageChanges)) {
                              showCancelConfirmation();
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 24,
                          alignment: Alignment.center,
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: isEditing
                                  ? () => showCancelConfirmation()
                                  : () => Navigator.pop(context),
                              child: Text(
                                isEditing ? '취소' : '닫기',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            if (isEditing)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'p.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 70,
                                    height: 32,
                                    child: TextField(
                                      controller: pageNumberController,
                                      focusNode: pageNumberFocusNode,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: pageNumberError
                                            ? Colors.red
                                            : (isDark ? Colors.white : Colors.black),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: pageNumberError ? Colors.red : Colors.grey[400]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: pageNumberError ? Colors.red : Colors.grey[400]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: pageNumberError ? Colors.red : const Color(0xFF5B7FFF),
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final parsed = int.tryParse(value);
                                        if (parsed != null && parsed > totalPages) {
                                          if (!hasShownPageError) {
                                            HapticFeedback.vibrate();
                                            CustomSnackbar.show(
                                              parentContext,
                                              message: '총 페이지 수($totalPages)를 초과할 수 없습니다',
                                              type: SnackbarType.error,
                                              rootOverlay: true,
                                              aboveKeyboard: true,
                                            );
                                            hasShownPageError = true;
                                          }
                                          setModalState(() {
                                            pageNumberError = true;
                                            editingPageNumber = parsed;
                                          });
                                        } else {
                                          hasShownPageError = false;
                                          setModalState(() {
                                            pageNumberError = false;
                                            editingPageNumber = parsed;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                editingPageNumber != null ? 'p.$editingPageNumber' : '페이지 미설정',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            if (isEditing)
                              TextButton(
                                onPressed: (isSaving || pageNumberError)
                                    ? null
                                    : () async {
                                        setModalState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          await Supabase.instance.client
                                              .from('book_images')
                                              .update({
                                                'extracted_text': textController.text,
                                                'page_number': editingPageNumber,
                                              })
                                              .eq('id', imageId);
                                          _editedTexts.remove(imageId);
                                          _cachedImages = null;
                                          _bookImagesFuture = fetchBookImages(_currentBook.id!);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            if (mounted) {
                                              setState(() {});
                                            }
                                            CustomSnackbar.show(
                                              this.context,
                                              message: '저장되었습니다',
                                              type: SnackbarType.success,
                                            );
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            isSaving = false;
                                          });
                                        }
                                      },
                                child: Text(
                                  isSaving ? '저장 중...' : '저장',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSaving ? Colors.grey : const Color(0xFF5B7FFF),
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  _confirmDeleteImage(imageId, imageUrl, dismissParentOnDelete: true);
                                },
                                child: Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: hasImage
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showFullScreenImage(imageId, imageUrl!),
                                  child: Container(
                                    width: double.infinity,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Hero(
                                            tag: 'book_image_$imageId',
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl!,
                                              cacheManager: BookImageCacheManager.instance,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                                child: Container(
                                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                child: Icon(
                                                  CupertinoIcons.photo,
                                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                _showReExtractConfirmation(
                                                  imageUrl: imageUrl!,
                                                  onConfirm: (extractedOcrText) {
                                                    setModalState(() {
                                                      textController.text = extractedOcrText;
                                                    });
                                                  },
                                                );
                                              },
                                              behavior: HitTestBehavior.opaque,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.document_scanner_outlined,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '텍스트 추출',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                _showReplaceImageOptionsOverModal(
                                                  imageId: imageId,
                                                  currentText: textController.text,
                                                  onReplaced: (newImageUrl) {
                                                    if (newImageUrl != null) {
                                                      setModalState(() {
                                                        imageUrl = newImageUrl;
                                                      });
                                                    }
                                                  },
                                                );
                                              },
                                              behavior: HitTestBehavior.opaque,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.arrow_2_squarepath,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '교체하기',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (hasImage) const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.doc_text,
                                        size: 18,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '인상적인 문구',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isEditing)
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (textController.text.isNotEmpty) {
                                              Clipboard.setData(ClipboardData(text: textController.text));
                                              CustomSnackbar.show(context, message: '텍스트가 복사되었습니다.', rootOverlay: true, bottomOffset: 40);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.doc_on_clipboard,
                                                size: 14,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '복사하기',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              isEditing = true;
                                            });
                                            Future.delayed(const Duration(milliseconds: 100), () {
                                              focusNode.requestFocus();
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons.pencil,
                                                size: 14,
                                                color: Color(0xFF5B7FFF),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                '수정하기',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF5B7FFF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          textController.clear();
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.trash,
                                            size: 14,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '모두 지우기',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 150,
                                ),
                                decoration: BoxDecoration(
                                  color: (isEditing || textController.text.isNotEmpty)
                                      ? (isDark ? Colors.grey[900] : Colors.grey[100])
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: (isEditing || textController.text.isNotEmpty)
                                      ? Border.all(
                                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                        )
                                      : null,
                                ),
                                child: isEditing
                                    ? TextField(
                                        controller: textController,
                                        focusNode: focusNode,
                                        maxLines: null,
                                        minLines: 6,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '텍스트를 입력하세요...',
                                          hintStyle: TextStyle(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.all(16),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: textController.text.isEmpty
                                            ? Text(
                                                '인상적인 문구가 없습니다.',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  height: 1.6,
                                                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                                                ),
                                              )
                                            : SelectableText(
                                                textController.text,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  height: 1.6,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                              ),
                                      ),
                              ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!isEditing)
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  if (textController.text.isNotEmpty) {
                                                    Clipboard.setData(ClipboardData(text: textController.text));
                                                    CustomSnackbar.show(context, message: '텍스트가 복사되었습니다.', rootOverlay: true, bottomOffset: 40);
                                                  }
                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.doc_on_clipboard,
                                                      size: 14,
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '복사하기',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              GestureDetector(
                                                onTap: () {
                                                  setModalState(() {
                                                    isEditing = true;
                                                  });
                                                  Future.delayed(const Duration(milliseconds: 100), () {
                                                    focusNode.requestFocus();
                                                  });
                                                },
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.pencil,
                                                      size: 14,
                                                      color: Color(0xFF5B7FFF),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '수정하기',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFF5B7FFF),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isEditing
                                              ? (isDark ? Colors.grey[900] : Colors.grey[100])
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isEditing
                                              ? Border.all(
                                                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                                )
                                              : null,
                                        ),
                                        child: isEditing
                                            ? TextField(
                                                controller: textController,
                                                focusNode: focusNode,
                                                maxLines: null,
                                                expands: true,
                                                keyboardType: TextInputType.multiline,
                                                textInputAction: TextInputAction.newline,
                                                textAlignVertical: TextAlignVertical.top,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  height: 1.6,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: '텍스트를 입력하세요...',
                                                  hintStyle: TextStyle(
                                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.all(16),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: textController.text.isEmpty
                                                    ? Text(
                                                        '인상적인 문구가 없습니다.',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          height: 1.6,
                                                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                                                        ),
                                                      )
                                                    : SelectableText(
                                                        textController.text,
                                                        style: TextStyle(
                                                          fontSize: 17,
                                                          height: 1.8,
                                                          color: isDark ? Colors.white : Colors.black,
                                                        ),
                                                      ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                    if (isEditing && isKeyboardOpen && (focusNode.hasFocus || pageNumberFocusNode.hasFocus) && !hideKeyboardAccessory)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: KeyboardAccessoryBar(
                          isDark: isDark,
                          showNavigation: true,
                          icon: CupertinoIcons.checkmark,
                          onUp: () {
                            if (focusNode.hasFocus) {
                              focusNode.unfocus();
                              pageNumberFocusNode.requestFocus();
                            }
                          },
                          onDown: () {
                            if (pageNumberFocusNode.hasFocus) {
                              pageNumberFocusNode.unfocus();
                              focusNode.requestFocus();
                            }
                          },
                          onDone: () {
                            setModalState(() {
                              hideKeyboardAccessory = true;
                            });
                            if (focusNode.hasFocus) {
                              focusNode.unfocus();
                            } else {
                              pageNumberFocusNode.unfocus();
                            }
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                setModalState(() {
                                  hideKeyboardAccessory = false;
                                });
                              }
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            );
          },
        );
      },
    ).then((_) {
      _editedTexts[imageId] = textController.text;
    });
  }

  Widget _buildMemorablePagesTab(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookImagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedImages == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasData) {
          _cachedImages = snapshot.data;
        }

        var images = List<Map<String, dynamic>>.from(_cachedImages ?? snapshot.data ?? []);

        images.sort((a, b) {
          switch (_memorableSortMode) {
            case 'page_asc':
              final pageA = a['page_number'] as int? ?? 0;
              final pageB = b['page_number'] as int? ?? 0;
              return pageA.compareTo(pageB);
            case 'page_desc':
              final pageA = a['page_number'] as int? ?? 0;
              final pageB = b['page_number'] as int? ?? 0;
              return pageB.compareTo(pageA);
            case 'date_asc':
              final dateA = a['created_at'] as String? ?? '';
              final dateB = b['created_at'] as String? ?? '';
              return dateA.compareTo(dateB);
            case 'date_desc':
            default:
              final dateA = a['created_at'] as String? ?? '';
              final dateB = b['created_at'] as String? ?? '';
              return dateB.compareTo(dateA);
          }
        });

        if (images.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo_on_rectangle,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 추가된 사진이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '하단 + 버튼으로 추가해보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSelectionMode)
                    Text(
                      '${_selectedImageIds.length}개 선택됨',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _memorableSortMode = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'page_desc',
                          child: Row(
                            children: [
                              if (_memorableSortMode == 'page_desc')
                                const Icon(Icons.check, size: 18, color: Color(0xFF5B7FFF))
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              const Text('페이지 높은순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'page_asc',
                          child: Row(
                            children: [
                              if (_memorableSortMode == 'page_asc')
                                const Icon(Icons.check, size: 18, color: Color(0xFF5B7FFF))
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              const Text('페이지 낮은순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'date_desc',
                          child: Row(
                            children: [
                              if (_memorableSortMode == 'date_desc')
                                const Icon(Icons.check, size: 18, color: Color(0xFF5B7FFF))
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              const Text('최근 기록순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'date_asc',
                          child: Row(
                            children: [
                              if (_memorableSortMode == 'date_asc')
                                const Icon(Icons.check, size: 18, color: Color(0xFF5B7FFF))
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              const Text('오래된 기록순'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_up_arrow_down,
                              size: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _memorableSortMode.contains('page') ? '페이지' : '날짜',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (_isSelectionMode && _selectedImageIds.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _deleteSelectedImages(),
                          icon: const Icon(
                            CupertinoIcons.trash,
                            size: 18,
                            color: Color(0xFFFF3B30),
                          ),
                          label: const Text(
                            '삭제',
                            style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_isSelectionMode) {
                              _selectedImageIds.clear();
                            }
                            _isSelectionMode = !_isSelectionMode;
                          });
                        },
                        child: Text(
                          _isSelectionMode ? '완료' : '선택',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B7FFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 100),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
            final imageId = image['id'] as String;
            final imageUrl = image['image_url'] as String?;
            final extractedText = image['extracted_text'] as String?;
            final pageNumber = image['page_number'] as int?;
            final createdAt = image['created_at'] as String?;
            final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;
            final ocrService = GoogleVisionOcrService();
            final previewText = ocrService.getPreviewText(extractedText, maxLines: 2);
            final isSelected = _selectedImageIds.contains(imageId);

            String formattedDate = '';
            if (createdAt != null) {
              try {
                final date = DateTime.parse(createdAt);
                formattedDate = '${date.month}/${date.day}';
              } catch (_) {}
            }

            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedImageIds.remove(imageId);
                    } else {
                      _selectedImageIds.add(imageId);
                    }
                  });
                } else {
                  _showExistingImageModal(
                    imageId,
                    imageUrl,
                    extractedText,
                    pageNumber: pageNumber,
                  );
                }
              },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImageUrl)
                          Hero(
                            tag: 'book_image_$imageId',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl!,
                                  cacheManager: BookImageCacheManager.instance,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                    highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                    child: Container(
                                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    child: Icon(
                                      CupertinoIcons.photo,
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: hasImageUrl ? 12 : 16,
                              right: 8,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  previewText.isNotEmpty ? previewText : '탭하여 상세 보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: previewText.isNotEmpty
                                        ? (isDark ? Colors.grey[300] : Colors.grey[800])
                                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (pageNumber != null || formattedDate.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (pageNumber != null)
                                        Text(
                                          'p.$pageNumber',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (pageNumber != null && formattedDate.isNotEmpty)
                                        Text(
                                          ' · ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                                          ),
                                        ),
                                      if (formattedDate.isNotEmpty)
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF5B7FFF)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF5B7FFF)
                                    : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressHistoryTab(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _progressHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProgressHistorySkeleton(isDark);
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chart_bar,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '진행률 기록이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final spots = data.asMap().entries.map((entry) {
          final idx = entry.key;
          final page = entry.value['page'] as int;
          return FlSpot(idx.toDouble(), page.toDouble());
        }).toList();

        final maxPage = data.isNotEmpty
            ? (data.map((e) => e['page'] as int).reduce((a, b) => a > b ? a : b))
                .toDouble()
            : 100.0;

        final dailyPagesSpots = data.asMap().entries.map((entry) {
          final idx = entry.key;
          final page = entry.value['page'] as int;
          final prevPage = idx > 0 ? data[idx - 1]['page'] as int : 0;
          final dailyPages = (page - prevPage).toDouble();
          return FlSpot(idx.toDouble(), dailyPages);
        }).toList();

        final maxDailyPage = dailyPagesSpots.isNotEmpty
            ? dailyPagesSpots
                .map((spot) => spot.y)
                .reduce((a, b) => a > b ? a : b)
            : 50.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '📈 누적 페이지',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (_attemptCount > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_attemptCount번째 · $_attemptEncouragement',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B7FFF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${data.length}일 기록',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B7FFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('누적 페이지', const Color(0xFF5B7FFF), isDark),
                        const SizedBox(width: 24),
                        _buildLegendItem('일일 페이지', const Color(0xFF10B981), isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chartWidth = constraints.maxWidth - 40;
                          final barWidth = data.length > 1
                              ? (chartWidth / data.length * 0.4).clamp(4.0, 16.0)
                              : 16.0;

                          final scaledMaxY = (maxPage * 1.1).ceilToDouble();
                          final barScaleFactor = scaledMaxY / (maxDailyPage > 0 ? maxDailyPage * 1.5 : 1);

                          return LineChart(
                            LineChartData(
                              lineBarsData: [
                                ...dailyPagesSpots.map((spot) {
                                  final scaledY = spot.y * barScaleFactor * 0.3;
                                  return LineChartBarData(
                                    spots: [
                                      FlSpot(spot.x, 0),
                                      FlSpot(spot.x, scaledY.clamp(0, scaledMaxY * 0.35)),
                                    ],
                                    isCurved: false,
                                    color: const Color(0xFF10B981),
                                    barWidth: barWidth,
                                    dotData: const FlDotData(show: false),
                                  );
                                }),
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5B7FFF), Color(0xFF4A6FE8)],
                                  ),
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: const Color(0xFF5B7FFF),
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF5B7FFF).withValues(alpha: 0.15),
                                        const Color(0xFF5B7FFF).withValues(alpha: 0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= data.length) {
                                        return const SizedBox();
                                      }
                                      final date =
                                          data[idx]['created_at'] as DateTime;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${date.month}/${date.day}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    },
                                    interval: data.length > 5
                                        ? (data.length / 4).ceilToDouble()
                                        : 1,
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                  ),
                                  left: BorderSide(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              minX: -0.5,
                              maxX: data.length - 0.5,
                              minY: 0,
                              maxY: scaledMaxY,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildReadingStateAnalysis(isDark, data),
              const SizedBox(height: 16),
              Text(
                '📅 일별 기록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...data.reversed.take(5).map((record) {
                final date = record['created_at'] as DateTime;
                final page = record['page'] as int;
                final index = data.indexOf(record);
                final prevPage = index > 0 ? data[index - 1]['page'] as int : 0;
                final pagesRead = page - prevPage;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7FFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B7FFF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '누적: $page 페이지',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+$pagesRead',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            '페이지',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showFullTitleDialog(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '도서 제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: title));
                          Navigator.pop(context);
                          CustomSnackbar.show(
                            context,
                            message: '제목이 복사되었습니다',
                            type: SnackbarType.success,
                            bottomOffset: 40,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc_on_clipboard,
                                size: 18,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '복사하기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 7,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showBookstoreSelectSheet(title);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B7FFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_up_right_square,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '서점에서 보기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSearchTitle(String title) {
    final hyphenIndex = title.indexOf(' - ');
    if (hyphenIndex > 0) {
      return title.substring(0, hyphenIndex).trim();
    }
    final dashIndex = title.indexOf('-');
    if (dashIndex > 0) {
      return title.substring(0, dashIndex).trim();
    }
    return title.trim();
  }

  void _showBookstoreSelectSheet(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchTitle = _getSearchTitle(title);
    final encodedTitle = Uri.encodeComponent(searchTitle);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '서점 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$searchTitle" 검색',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    _buildBookstoreButton(
                      isDark: isDark,
                      logoPath: 'assets/images/logo-aladin.png',
                      name: '알라딘',
                      onTap: () async {
                        Navigator.pop(context);
                        final url = 'https://www.aladin.co.kr/search/wsearchresult.aspx?SearchWord=$encodedTitle';
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildBookstoreButton(
                      isDark: isDark,
                      logoPath: 'assets/images/logo-yes24.png',
                      name: 'Yes24',
                      onTap: () async {
                        Navigator.pop(context);
                        final url = 'https://www.yes24.com/Product/Search?domain=ALL&query=$encodedTitle';
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildBookstoreButton(
                      isDark: isDark,
                      logoPath: 'assets/images/logo-kyobo.svg',
                      name: '교보문고',
                      isSvg: true,
                      onTap: () async {
                        Navigator.pop(context);
                        final url = 'https://search.kyobobook.co.kr/search?keyword=$encodedTitle';
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookstoreButton({
    required bool isDark,
    required String logoPath,
    required String name,
    required VoidCallback onTap,
    bool isSvg = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(4),
              child: isSvg
                  ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                  : Image.asset(logoPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyTargetChangeDialog() async {
    await DailyTargetDialog.show(
      context: context,
      book: _currentBook,
      pagesLeft: _pagesLeft,
      daysLeft: _daysLeft,
      onSave: (newDailyTarget) {
        setState(() {
          _currentBook = _currentBook.copyWith(
            dailyTargetPages: newDailyTarget,
          );
        });
      },
    );
  }

  Widget _buildKoreanDatePicker({
    required bool isDark,
    required DateTime selectedDate,
    required DateTime minimumDate,
    required Function(DateTime) onDateChanged,
  }) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear + i);
    final months = List.generate(12, (i) => i + 1);

    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    final yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selectedDate.year),
    );
    final monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    final dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );

    Widget buildWheel({
      required List<int> items,
      required FixedExtentScrollController controller,
      required String suffix,
      required Function(int) onSelected,
      double width = 80,
    }) {
      return SizedBox(
        width: width,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 40,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.5,
          perspective: 0.003,
          onSelectedItemChanged: (index) => onSelected(items[index]),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: items.length,
            builder: (context, index) {
              final isSelected = controller.hasClients
                  ? controller.selectedItem == index
                  : items.indexOf(items[index]) == controller.initialItem;
              return Center(
                child: Text(
                  '${items[index]}$suffix',
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    int currentYear_ = selectedDate.year;
    int currentMonth = selectedDate.month;
    int currentDay = selectedDate.day;

    return StatefulBuilder(
      builder: (context, setState) {
        final daysInCurrentMonth = getDaysInMonth(currentYear_, currentMonth);
        final validDay = currentDay > daysInCurrentMonth ? daysInCurrentMonth : currentDay;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildWheel(
              items: years,
              controller: yearController,
              suffix: '년',
              width: 90,
              onSelected: (year) {
                setState(() {
                  currentYear_ = year;
                  final maxDay = getDaysInMonth(year, currentMonth);
                  if (currentDay > maxDay) {
                    currentDay = maxDay;
                    dayController.jumpToItem(currentDay - 1);
                  }
                });
                final newDate = DateTime(year, currentMonth, validDay);
                if (!newDate.isBefore(minimumDate)) {
                  onDateChanged(newDate);
                }
              },
            ),
            buildWheel(
              items: months,
              controller: monthController,
              suffix: '월',
              width: 70,
              onSelected: (month) {
                setState(() {
                  currentMonth = month;
                  final maxDay = getDaysInMonth(currentYear_, month);
                  if (currentDay > maxDay) {
                    currentDay = maxDay;
                    dayController.jumpToItem(currentDay - 1);
                  }
                });
                final newDate = DateTime(currentYear_, month, validDay);
                if (!newDate.isBefore(minimumDate)) {
                  onDateChanged(newDate);
                }
              },
            ),
            buildWheel(
              items: List.generate(daysInCurrentMonth, (i) => i + 1),
              controller: dayController,
              suffix: '일',
              width: 70,
              onSelected: (day) {
                setState(() {
                  currentDay = day;
                });
                final newDate = DateTime(currentYear_, currentMonth, day);
                if (!newDate.isBefore(minimumDate)) {
                  onDateChanged(newDate);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateTargetDateDialogWithConfirm() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextAttempt = _attemptCount + 1;
    DateTime selectedDate = _currentBook.targetDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysRemaining = selectedDate.difference(DateTime.now()).inDays;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFFFF6B6B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '목표일 변경',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              '$nextAttempt번째 도전으로 변경됩니다',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: daysRemaining > 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            daysRemaining > 0 ? 'D-$daysRemaining' : 'D-Day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: daysRemaining > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildKoreanDatePicker(
                      isDark: isDark,
                      selectedDate: selectedDate,
                      minimumDate: DateTime.now(),
                      onDateChanged: (DateTime newDate) {
                        setModalState(() {
                          selectedDate = newDate;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _updateTargetDate(selectedDate, nextAttempt);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '변경하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateTargetDate(DateTime newDate, int newAttempt) async {
    final oldDaysLeft = _daysLeft;
    final updatedBook = _currentBook.copyWith(
      targetDate: newDate,
      attemptCount: newAttempt,
    );
    final result = await _bookService.updateBook(_currentBook.id!, updatedBook);

    if (result != null && mounted) {
      setState(() {
        _currentBook = result;
        _attemptCount = newAttempt;
      });

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );

      CustomSnackbar.show(
        context,
        message: '$newAttempt번째 도전 시작! D-$_daysLeft',
        type: SnackbarType.info,
        icon: Icons.flag,
      );
    }
  }
}
