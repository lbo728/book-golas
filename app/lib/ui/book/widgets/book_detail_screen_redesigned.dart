import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../domain/models/book.dart';
import '../../../data/services/book_service.dart';
import '../../../data/services/google_vision_ocr_service.dart';
import '../../core/ui/book_image_widget.dart';

/// 시니어 프로덕트 디자이너가 재설계한 독서 상세 화면
///
/// 디자인 원칙:
/// 1. Visual Hierarchy: D-day와 진행률을 최상단에 강조
/// 2. Card-based Layout: 정보를 논리적으로 그룹핑
/// 3. Breathing Space: 충분한 여백으로 가독성 향상
/// 4. Progressive Disclosure: 중요한 정보부터 노출
class BookDetailScreenRedesigned extends StatefulWidget {
  final Book book;

  const BookDetailScreenRedesigned({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreenRedesigned> createState() =>
      _BookDetailScreenRedesignedState();
}

class _BookDetailScreenRedesignedState extends State<BookDetailScreenRedesigned>
    with TickerProviderStateMixin {
  final BookService _bookService = BookService();
  late Book _currentBook;
  int? _todayStartPage;
  int? _todayTargetPage;
  late TabController _tabController;
  int _attemptCount = 1; // 도전 횟수
  Map<String, bool> _dailyAchievements = {}; // 일차별 목표 달성 현황 (날짜: 성공/실패)
  bool _useMockProgressData = false; // 🎨 진행률 히스토리 목업 데이터 사용 (실제 데이터 연결 완료)

  // 페이지 카운터 & 프로그레스바 애니메이션
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  int _animatedCurrentPage = 0;
  double _animatedProgress = 0.0;

  // 캐싱: Future를 한번만 생성하여 재사용
  late Future<List<Map<String, dynamic>>> _bookImagesFuture;
  late Future<List<Map<String, dynamic>>> _progressHistoryFuture;

  // 로컬 캐시: 서버 데이터 로드 완료 후 로컬에서 관리
  List<Map<String, dynamic>>? _cachedImages;

  // 메모리에 수정된 텍스트 저장 (저장 버튼 누르기 전까지 유지)
  final Map<String, String> _editedTexts = {};

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _todayStartPage = _currentBook.startDate.day;
    _todayTargetPage = _currentBook.targetDate.day;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 탭 변경 시 UI 업데이트
    });
    _loadDailyAchievements();

    // 페이지 애니메이션 초기화
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

    // Future를 initState에서 한번만 생성 (캐싱)
    _bookImagesFuture = fetchBookImages(_currentBook.id!);
    _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimController.dispose();
    super.dispose();
  }

  void _showTopLevelToast(BuildContext modalContext, String message) {
    final overlay = Overlay.of(modalContext, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 24,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Future<void> _loadDailyAchievements() async {
    // TODO: Supabase에서 일차별 달성 현황 불러오기
    // 임시로 더미 데이터 생성
    final achievements = <String, bool>{};
    final startDate = _currentBook.startDate;
    final now = DateTime.now();

    for (var i = 0; i < now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      // TODO: 실제 달성 여부 확인 로직 필요
      achievements[dateKey] = i % 3 != 1; // 임시: 3일에 한번 실패
    }

    setState(() {
      _dailyAchievements = achievements;
    });
  }

  int get _daysLeft {
    final now = DateTime.now();
    final target = _currentBook.targetDate;
    return target.difference(now).inDays;
  }

  double get _progressPercentage {
    if (_currentBook.totalPages == 0) return 0;
    return (_currentBook.currentPage / _currentBook.totalPages * 100)
        .clamp(0, 100);
  }

  int get _pagesLeft => (_currentBook.totalPages - _currentBook.currentPage)
      .clamp(0, _currentBook.totalPages);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        actions: [
          // 🎨 목업 데이터 토글 버튼
          Tooltip(
            message: _useMockProgressData ? '목업 데이터 끄기' : '목업 데이터 보기',
            child: IconButton(
              icon: Icon(
                _useMockProgressData
                    ? CupertinoIcons.chart_bar_circle_fill
                    : CupertinoIcons.chart_bar_circle,
                color: _useMockProgressData
                    ? const Color(0xFF5B7FFF)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              onPressed: () {
                setState(() {
                  _useMockProgressData = !_useMockProgressData;
                });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Section: D-day + Progress (축소)
                          _buildCompactHeroSection(isDark),
                          const SizedBox(height: 20),

                          // Book Info Card
                          _buildBookInfoCard(isDark),
                          const SizedBox(height: 16),

                          // Reading Schedule Card
                          _buildReadingScheduleCard(isDark),
                          const SizedBox(height: 16),

                          // Today's Goal Card with Achievement Stamps
                          _buildTodayGoalCardWithStamps(isDark),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Sticky Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
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
                  ],
                ),
              ),
            ),
          ),
          // Floating Update Button
          _buildFloatingUpdateButton(isDark),
        ],
      ),
    );
  }

  /// Compact Hero Section: 축소된 D-day + Progress
  Widget _buildCompactHeroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5B7FFF),
            Color(0xFF4A6FE8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7FFF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // D-day
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _daysLeft >= 0 ? 'D-$_daysLeft' : 'D+${_daysLeft.abs()}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _daysLeft >= 0 ? '남음' : '초과',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(_animatedProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_animatedCurrentPage/${_currentBook.totalPages}p',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _animatedProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Section: 가장 중요한 정보를 강력하게 표시 (원본 - 사용 안 함)
  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5B7FFF),
            Color(0xFF4A6FE8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7FFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // D-day Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _daysLeft >= 0 ? 'D-$_daysLeft' : 'D+${_daysLeft.abs()}',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _daysLeft >= 0 ? '남음' : '초과',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_currentBook.currentPage} / ${_currentBook.totalPages}p',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progressPercentage / 100,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_pagesLeft페이지 남음',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Book Info Card: 책 정보
  Widget _buildBookInfoCard(bool isDark) {
    final isCompleted = _currentBook.currentPage >= _currentBook.totalPages &&
        _currentBook.totalPages > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          Hero(
            tag: 'book_cover_${_currentBook.id}',
            child: Container(
              width: 90,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BookImageWidget(
                  imageUrl: _currentBook.imageUrl,
                  iconSize: 60,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Book Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : const Color(0xFF5B7FFF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? '✓ 완독' : '● 독서 중',
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF5B7FFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  _currentBook.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Author
                if (_currentBook.author != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _currentBook.author!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reading Schedule Card: 독서 일정
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
                          '$_attemptCount번째 도전',
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

  /// Today's Goal Card: 오늘의 목표
  Widget _buildTodayGoalCard() {
    final todayPages = _todayTargetPage != null && _todayStartPage != null
        ? (_todayTargetPage! - _todayStartPage!)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3E0),
            Color(0xFFFFE0B2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.flame_fill,
                      size: 20,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '오늘의 목표',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showTodayGoalSheet,
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
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayPages > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$todayPages',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '페이지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$_todayStartPage ~ $_todayTargetPage 페이지',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const Text(
              '아직 목표가 설정되지 않았습니다',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Memorable Pages Section: 인상적인 페이지
  Widget _buildMemorablePagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    CupertinoIcons.photo,
                    size: 20,
                    color: Color(0xFF5B7FFF),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '인상적인 페이지',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showAddMemorablePageModal,
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text(
                '추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchBookImages(_currentBook.id!),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final images = snapshot.data ?? [];

            if (images.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '아직 추가된 사진이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                final imageUrl = image['image_url'] as String?;
                final pageNumber = image['page_number'] as int?;
                final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return GestureDetector(
                  onTap: () => _showExistingImageModal(
                    image['id'] as String,
                    imageUrl,
                    image['extracted_text'] as String?,
                    pageNumber: pageNumber,
                  ),
                  onLongPress: () => _confirmDeleteImage(
                    image['id'] as String,
                    imageUrl,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.doc_text,
                                    size: 32,
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                      ),
                      if (pageNumber != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'p.$pageNumber',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Progress History Section: 진행률 히스토리
  Widget _buildProgressHistorySection() {
    return Column(
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
                CupertinoIcons.chart_bar_fill,
                size: 20,
                color: Color(0xFF5B7FFF),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '진행률 히스토리',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchProgressHistory(_currentBook.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
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
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '진행률 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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

              return SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
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
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF5B7FFF),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5B7FFF).withOpacity(0.2),
                              const Color(0xFF5B7FFF).withOpacity(0.0),
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
                              '${value.toInt()}p',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox();
                            }
                            final date = data[idx]['created_at'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          interval:
                              (data.length / 4).ceilToDouble().clamp(1, 999),
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Update Page Button: 현재 페이지 업데이트 버튼
  Widget _buildUpdatePageButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showUpdatePageDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B7FFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          '현재 페이지 업데이트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Dialog and Bottom Sheet Methods

  Future<void> _showUpdatePageDialog() async {
    final TextEditingController controller = TextEditingController(
      text: '',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? errorText;
    bool isValid = false;

    String? validatePage(String value) {
      if (value.isEmpty) {
        return null;
      }
      final page = int.tryParse(value);
      if (page == null) {
        return '숫자를 입력해주세요';
      }
      if (page < 0) {
        return '0 이상의 페이지를 입력해주세요';
      }
      if (page > _currentBook.totalPages) {
        return '총 페이지(${_currentBook.totalPages})를 초과할 수 없습니다';
      }
      if (page <= _currentBook.currentPage) {
        return '현재 페이지(${_currentBook.currentPage}) 이하입니다';
      }
      return null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 페이지 업데이트',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '현재 ${_currentBook.currentPage}p',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5B7FFF),
                        ),
                      ),
                      Text(
                        ' / 총 ${_currentBook.totalPages}p',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (value) {
                      setModalState(() {
                        errorText = validatePage(value);
                        isValid = errorText == null && value.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '새 페이지 번호',
                      hintText: '${_currentBook.currentPage + 1} ~ ${_currentBook.totalPages}',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorText != null ? Colors.red : const Color(0xFF5B7FFF),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
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
                          onPressed: isValid
                              ? () {
                                  final page = int.parse(controller.text);
                                  Navigator.pop(context);
                                  _updateCurrentPage(page);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            disabledBackgroundColor: isDark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '업데이트',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isValid
                                  ? Colors.white
                                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
        // 애니메이션 실행
        _animateProgress(oldPage, newPage, oldProgress, newProgress);

        setState(() {
          _currentBook = updatedBook;
        });

        if (mounted) {
          final pagesRead = newPage - oldPage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('+$pagesRead 페이지! ${newPage}p 도달 🎉'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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

  void _showUpdateTargetDateDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentBook.targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final updatedBook = _currentBook.copyWith(targetDate: picked);
      final result =
          await _bookService.updateBook(_currentBook.id!, updatedBook);

      if (result != null) {
        setState(() {
          _currentBook = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('목표 완료일이 변경되었습니다.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  void _showTodayGoalSheet() {
    final startController =
        TextEditingController(text: _todayStartPage?.toString() ?? '');
    final endController =
        TextEditingController(text: _todayTargetPage?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘의 분량 설정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: startController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '시작 페이지',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '목표 페이지',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final start = int.tryParse(startController.text);
                    final end = int.tryParse(endController.text);
                    if (start != null && end != null && start < end) {
                      setState(() {
                        _todayStartPage = start;
                        _todayTargetPage = end;
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

    // 정렬: 1순위 page_number 내림차순, 2순위 created_at 내림차순
    images.sort((a, b) {
      final pageA = a['page_number'] as int?;
      final pageB = b['page_number'] as int?;

      // page_number가 있는 항목이 우선
      if (pageA != null && pageB == null) return -1;
      if (pageA == null && pageB != null) return 1;
      if (pageA != null && pageB != null) {
        final pageCompare = pageB.compareTo(pageA); // 내림차순
        if (pageCompare != 0) return pageCompare;
      }

      // page_number가 같거나 둘 다 null이면 created_at으로 정렬
      final dateA = a['created_at'] as String;
      final dateB = b['created_at'] as String;
      return dateB.compareTo(dateA); // 내림차순
    });

    return images;
  }

  Future<void> _deleteBookImage(String imageId, String? imageUrl) async {
    // 이미지가 있는 경우에만 스토리지에서 삭제
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

    // 로컬 캐시에서 직접 제거 (리로딩 없이 즉시 반영)
    setState(() {
      if (_cachedImages != null) {
        _cachedImages = _cachedImages!.where((img) => img['id'] != imageId).toList();
      }
      // 백그라운드에서 서버 데이터 동기화
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });
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
          return _DraggableDismissImage(
            animation: animation,
            imageBytes: imageBytes,
          );
        },
      ),
    );
  }

  Future<void> _uploadAndSaveMemorablePage({
    Uint8List? imageBytes,
    required String extractedText,
    int? pageNumber,
  }) async {
    String? publicUrl;

    // 이미지가 있으면 스토리지에 업로드
    if (imageBytes != null) {
      final fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = Supabase.instance.client.storage;
      await storage.from('book-images').uploadBinary(fileName, imageBytes,
          fileOptions: const FileOptions(upsert: true));
      publicUrl = storage.from('book-images').getPublicUrl(fileName);
    }

    // insert 후 새 레코드 반환받기
    final result = await Supabase.instance.client.from('book_images').insert({
      'book_id': _currentBook.id,
      'image_url': publicUrl,
      'caption': '',
      'extracted_text': extractedText.isEmpty ? null : extractedText,
      'page_number': pageNumber,
    }).select().single();

    // 로컬 캐시에 직접 추가 (리로딩 없이 즉시 반영)
    setState(() {
      if (_cachedImages != null) {
        _cachedImages = [result, ..._cachedImages!];
      }
      // 백그라운드에서 서버 데이터 동기화
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('인상적인 페이지가 저장되었습니다.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// 인상적인 페이지 추가 모달 (새 UX 플로우)
  void _showAddMemorablePageModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Uint8List? fullImageBytes; // 원본 이미지 (스토리지에 저장됨)
    String extractedText = '';
    int? pageNumber;
    bool isUploading = false;
    String? pageValidationError; // 페이지 유효성 검사 에러

    final textController = TextEditingController();
    final pageController = TextEditingController();
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
            return GestureDetector(
              onTap: () {
                textFocusNode.unfocus();
                pageFocusNode.unfocus();
              },
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
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
                      // 헤더
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              '인상적인 페이지',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: isUploading || textController.text.isEmpty || pageValidationError != null
                                  ? null
                                  : () async {
                                      setModalState(() => isUploading = true);
                                      try {
                                        await _uploadAndSaveMemorablePage(
                                          imageBytes: fullImageBytes,
                                          extractedText: textController.text,
                                          pageNumber: int.tryParse(pageController.text),
                                        );
                                      } finally {
                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                              child: Text(
                                '업로드',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: (isUploading || textController.text.isEmpty || pageValidationError != null)
                                      ? Colors.grey
                                      : const Color(0xFF5B7FFF),
                                ),
                              ),
                            ),
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
                              // 섬네일 영역
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
                                                      CupertinoIcons.fullscreen,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '전체보기',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
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
                                                        onImageSelected: (imageBytes, ocrText, extractedPageNum) {
                                                          setModalState(() {
                                                            fullImageBytes = imageBytes;
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
                                          onImageSelected: (imageBytes, ocrText, extractedPageNum) {
                                            setModalState(() {
                                              fullImageBytes = imageBytes;
                                              extractedText = ocrText;
                                              textController.text = ocrText;
                                              if (extractedPageNum != null) {
                                                pageNumber = extractedPageNum;
                                                pageController.text = extractedPageNum.toString();
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

                              // 페이지 수 필드
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
                                              });
                                              return;
                                            }
                                            final parsed = int.tryParse(value);
                                            if (parsed != null) {
                                              if (parsed > _currentBook.totalPages) {
                                                setModalState(() {
                                                  pageNumber = parsed;
                                                  pageValidationError = '전체 페이지 수를 초과할 수 없습니다.';
                                                });
                                              } else {
                                                setModalState(() {
                                                  pageNumber = parsed;
                                                  pageValidationError = null;
                                                });
                                              }
                                            }
                                          },
                                          decoration: InputDecoration(
                                            hintText: '페이지 수',
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
                                    const SizedBox(height: 6),
                                    Text(
                                      pageValidationError!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 텍스트 영역 레이블
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
                                    hintText: '기억하고 싶은 문구를 입력하세요...',
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '이미지를 추가하면 자동으로 텍스트를 추출합니다.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    // 업로드 중 스피너 오버레이
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
            );
          },
        );
      },
    );
  }

  /// 이미지 소스 선택 액션시트
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('시뮬레이터에서는 카메라를 사용할 수 없습니다.'),
                            ),
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

  /// 이미지 선택 → 크롭 → OCR 텍스트 추출
  Future<void> _pickImageAndExtractText(
    ImageSource source,
    Function(Uint8List imageBytes, String ocrText, int? pageNumber) onComplete,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    // 원본 이미지 바이트
    final fullImageBytes = await pickedFile.readAsBytes();

    if (!mounted) return;

    // 로딩 다이얼로그 표시
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
                  '페이지 번호 추출 중...',
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

    // 1단계: 전체 이미지에서 페이지 번호 먼저 추출 시도
    final ocrService = GoogleVisionOcrService();
    final fullImageOcrText = await ocrService.extractTextFromBytes(fullImageBytes) ?? '';
    int? pageNumber = _extractPageNumber(fullImageOcrText);

    if (!mounted) return;

    // 로딩 다이얼로그 닫기
    Navigator.of(context, rootNavigator: true).pop();

    // 2단계: 크롭 화면 표시 (본문 텍스트 추출용)
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

    if (croppedFile == null) return;

    if (!mounted) return;

    // 텍스트 추출 로딩 다이얼로그 표시
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

    // 3단계: 크롭된 영역에서 본문 텍스트 OCR 추출
    final croppedBytes = await croppedFile.readAsBytes();
    final ocrText = await ocrService.extractTextFromBytes(croppedBytes) ?? '';

    // 크롭 영역에서도 페이지 번호를 찾지 못했으면 다시 시도
    if (pageNumber == null) {
      pageNumber = _extractPageNumber(ocrText);
    }

    if (!mounted) return;

    // 로딩 다이얼로그 닫기
    Navigator.of(context, rootNavigator: true).pop();

    // 콜백 호출 (원본 이미지 + 크롭 영역 OCR 텍스트 + 페이지 번호)
    onComplete(fullImageBytes, ocrText, pageNumber);
  }

  /// OCR 텍스트에서 페이지 번호 추출
  int? _extractPageNumber(String text) {
    // 여러 패턴으로 페이지 번호 추출 시도
    // 책의 페이지 번호는 보통 모서리에 위치하고 1-4자리 숫자

    final patterns = [
      // 명시적 페이지 표시
      RegExp(r'[-–]\s*(\d{1,4})\s*[-–]'), // - 123 -
      RegExp(r'[pP]\.?\s*(\d{1,4})'), // p.123, P 123
      RegExp(r'[pP]age\s*(\d{1,4})', caseSensitive: false), // page 123
      RegExp(r'(\d{1,4})\s*페이지'), // 123페이지
      RegExp(r'(\d{1,4})\s*쪽'), // 123쪽

      // 줄의 시작이나 끝에 있는 단독 숫자 (페이지 번호 패턴)
      RegExp(r'^\s*(\d{1,4})\s*$', multiLine: true), // 단독 줄의 숫자
      RegExp(r'^(\d{1,4})\s+\S', multiLine: true), // 줄 시작의 숫자 + 공백 + 텍스트
      RegExp(r'\S\s+(\d{1,4})$', multiLine: true), // 텍스트 + 공백 + 줄 끝의 숫자

      // 괄호 안의 숫자
      RegExp(r'\((\d{1,4})\)'), // (123)
      RegExp(r'\[(\d{1,4})\]'), // [123]

      // 텍스트 처음이나 끝에 있는 숫자 (OCR 결과의 첫/마지막 숫자)
      RegExp(r'^(\d{1,4})\b'), // 텍스트 시작의 숫자
      RegExp(r'\b(\d{1,4})$'), // 텍스트 끝의 숫자
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final pageStr = match.group(1);
        if (pageStr != null) {
          final page = int.tryParse(pageStr);
          // 유효한 페이지 번호 범위: 1-9999, 챕터/섹션 번호 제외
          if (page != null && page > 0 && page < 10000) {
            // 소수점이 있는 섹션 번호 제외 (예: 4.1.1)
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
    // 🎨 목업 데이터 모드
    if (_useMockProgressData) {
      await Future.delayed(const Duration(milliseconds: 300)); // 로딩 시뮬레이션
      return _generateMockProgressData();
    }

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

  /// 범례 아이템 빌더
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

  /// 🎨 목업 진행률 데이터 생성 (더 현실적인 패턴)
  List<Map<String, dynamic>> _generateMockProgressData() {
    final now = DateTime.now();
    final startDate = _currentBook.startDate;
    final daysPassed = now.difference(startDate).inDays.clamp(0, 20);

    final List<Map<String, dynamic>> mockData = [];
    int currentPage = 0;

    // 시작일부터 오늘까지의 진행 데이터 생성
    for (int i = 0; i <= daysPassed; i++) {
      final date = startDate.add(Duration(days: i));
      final dayOfWeek = date.weekday; // 1=월요일, 7=일요일

      // 현실적인 독서 패턴:
      // - 주말(토,일)에 더 많이 읽음
      // - 가끔 안 읽는 날도 있음 (20% 확률)
      // - 평일: 15-30페이지
      // - 주말: 40-60페이지

      final skipReading = (i % 5 == 2); // 5일에 한번 쉼

      if (!skipReading) {
        int pagesRead;

        if (dayOfWeek == 6 || dayOfWeek == 7) {
          // 주말 - 많이 읽음
          pagesRead = 40 + (i % 20);
        } else if (dayOfWeek == 5) {
          // 금요일 - 중간
          pagesRead = 25 + (i % 15);
        } else {
          // 평일 - 적게 읽음
          pagesRead = 15 + (i % 15);
        }

        currentPage += pagesRead;

        // 하루에 여러 번 읽는 경우도 있음 (30% 확률)
        if (i % 3 == 0) {
          // 첫 번째 독서 세션 (점심)
          mockData.add({
            'page': (currentPage * 0.4).toInt().clamp(0, _currentBook.totalPages),
            'created_at': date.add(Duration(hours: 12 + (i % 2))),
          });
        }

        // 주요 독서 세션 (저녁)
        mockData.add({
          'page': currentPage.clamp(0, _currentBook.totalPages),
          'created_at': date.add(Duration(
            hours: 20 + (i % 3),
            minutes: (i * 13) % 60,
          )),
        });
      }
    }

    return mockData;
  }

  /// 새로운 위젯: 오늘의 목표 카드 with 스탬프
  Widget _buildTodayGoalCardWithStamps(bool isDark) {
    final totalDays =
        _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3E0),
            Color(0xFFFFE0B2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
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
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  size: 20,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '목표 달성 현황',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 스탬프 UI
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalDays,
              itemBuilder: (context, index) {
                final date = _currentBook.startDate.add(Duration(days: index));
                final dateKey =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final now = DateTime.now();
                final isFuture =
                    date.isAfter(DateTime(now.year, now.month, now.day));
                final isAchieved = _dailyAchievements[dateKey];

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAchieved == true
                          ? const Color(0xFF10B981)
                          : isAchieved == false
                              ? const Color(0xFFEF4444)
                              : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 아이콘
                      if (isFuture)
                        Icon(
                          CupertinoIcons.circle,
                          size: 32,
                          color: Colors.grey[400],
                        )
                      else if (isAchieved == true)
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 32,
                          color: Color(0xFF10B981),
                        )
                      else
                        const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 32,
                          color: Color(0xFFEF4444),
                        ),
                      const SizedBox(height: 8),
                      // 날짜
                      Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Day ${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 탭 바만 반환 (스티키 헤더용)
  Widget _buildTabBarOnly(bool isDark) {
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
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '인상적인 페이지',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _tabController.index == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _tabController.index == 0
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '진행률 히스토리',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _tabController.index == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _tabController.index == 1
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 슬라이딩 인디케이터
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: tabWidth * _tabController.index,
                      width: tabWidth,
                      height: 2,
                      child: Container(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 탭 섹션: 인상적인 페이지 + 진행률 히스토리 (레거시)
  Widget _buildTabbedSection(bool isDark) {
    return Column(
      children: [
        // 탭 헤더 - 슬라이딩 애니메이션 적용
        Container(
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
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '인상적인 페이지',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _tabController.index == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _tabController.index == 0
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '진행률 히스토리',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _tabController.index == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _tabController.index == 1
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 슬라이딩 인디케이터
              Positioned(
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width - 32; // 양쪽 패딩
                    final tabWidth = screenWidth / 2;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      transform: Matrix4.translationValues(
                        tabWidth * _tabController.index,
                        0,
                        0,
                      ),
                      width: tabWidth,
                      height: 2,
                      color: isDark ? Colors.white : Colors.black,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMemorablePagesTab(isDark),
              _buildProgressHistoryTab(isDark),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullExtractedText(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
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
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 20,
                          color: Color(0xFF5B7FFF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '추출된 텍스트',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SelectableText(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReplaceImageOptions(String imageId, String currentText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                  Navigator.pop(context);
                  _pickImageAndExtractText(
                    ImageSource.camera,
                    (imageBytes, ocrText, pageNumber) async {
                      await _replaceImage(imageId, imageBytes, ocrText.isEmpty ? currentText : ocrText, pageNumber);
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
                  Navigator.pop(context);
                  _pickImageAndExtractText(
                    ImageSource.gallery,
                    (imageBytes, ocrText, pageNumber) async {
                      await _replaceImage(imageId, imageBytes, ocrText.isEmpty ? currentText : ocrText, pageNumber);
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

  Future<void> _replaceImage(String imageId, Uint8List imageBytes, String extractedText, int? pageNumber) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('이미지가 교체되었습니다.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 교체 실패: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    }
  }

  void _showFullScreenImage(String imageId, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _DraggableDismissNetworkImage(
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
    String? imageUrl,
    String? extractedText, {
    int? pageNumber,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 메모리에 저장된 텍스트가 있으면 사용, 없으면 DB에서 가져온 값 사용
    final cachedText = _editedTexts[imageId] ?? extractedText ?? '';
    final textController = TextEditingController(text: cachedText);
    final focusNode = FocusNode();
    bool isEditing = false;
    bool isSaving = false;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
            }

            return GestureDetector(
              onTap: () {
                if (isEditing) {
                  focusNode.unfocus();
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
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
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '닫기',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              '인상적인 페이지',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (isEditing)
                              TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setModalState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          await Supabase.instance.client
                                              .from('book_images')
                                              .update({'extracted_text': textController.text})
                                              .eq('id', imageId);
                                          // 저장 성공 시 메모리 캐시 제거 (DB 값이 우선)
                                          _editedTexts.remove(imageId);
                                          _bookImagesFuture = fetchBookImages(_currentBook.id!);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: const Text('텍스트가 저장되었습니다.'),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                                margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
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
                                            child: Image.network(
                                              imageUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                  child: const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
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
                                                    CupertinoIcons.fullscreen,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '전체보기',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showReplaceImageOptions(imageId, textController.text);
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
                                mainAxisAlignment: hasImage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                                children: [
                                  if (hasImage)
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc_text,
                                          size: 18,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '추출된 텍스트',
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
                                              _showTopLevelToast(context, '텍스트가 복사되었습니다.');
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
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 150,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
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
                                                '추출된 텍스트가 없습니다.',
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
                                                    _showTopLevelToast(context, '텍스트가 복사되었습니다.');
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
                                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                          ),
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
                                                        '추출된 텍스트가 없습니다.',
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
                                    ),
                                    const SizedBox(height: 20),
                                  ],
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
      // 모달이 닫힐 때 수정된 텍스트를 메모리에 저장
      _editedTexts[imageId] = textController.text;
    });
  }

  Widget _buildMemorablePagesTab(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookImagesFuture, // 캐시된 Future 사용
      builder: (context, snapshot) {
        // 최초 로드 시에만 로딩 표시, 이후에는 캐시된 데이터 사용
        if (snapshot.connectionState == ConnectionState.waiting && _cachedImages == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 데이터 로드 완료 시 캐시에 저장
        if (snapshot.hasData) {
          _cachedImages = snapshot.data;
        }

        // 캐시된 데이터 우선 사용
        final images = _cachedImages ?? snapshot.data ?? [];

        if (images.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo_on_rectangle,
                  size: 64,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 추가된 사진이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddMemorablePageModal,
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: const Text('추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 고정된 추가 버튼
            GestureDetector(
              onTap: _showAddMemorablePageModal,
              child: Container(
                height: 56,
                margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      size: 24,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '추가',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 스크롤 가능한 리스트
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
            final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;
            final ocrService = GoogleVisionOcrService();
            final previewText = ocrService.getPreviewText(extractedText, maxLines: 2);

            return Dismissible(
              key: Key(imageId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                _confirmDeleteImage(imageId, imageUrl);
                return false;
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.trash_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => _showExistingImageModal(
                  imageId,
                  imageUrl,
                  extractedText,
                  pageNumber: pageNumber,
                ),
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
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
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
                            if (pageNumber != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'p.$pageNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
      future: _progressHistoryFuture, // 캐시된 Future 사용
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chart_bar,
                  size: 64,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
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

        // 일일 페이지 수 계산
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
              // 차트 컨테이너
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
                        Text(
                          '📈 누적 페이지',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
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
                    // 범례
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
                      child: Stack(
                        children: [
                          // 일일 페이지 막대 (배경)
                          LineChart(
                            LineChartData(
                              lineBarsData: dailyPagesSpots.map((spot) {
                                return LineChartBarData(
                                  spots: [
                                    FlSpot(spot.x, 0),
                                    spot,
                                  ],
                                  isCurved: false,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  barWidth: 8,
                                  dotData: const FlDotData(show: false),
                                );
                              }).toList(),
                              titlesData: const FlTitlesData(
                                show: false,
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              minY: 0,
                              maxY: maxDailyPage * 1.2,
                            ),
                          ),
                          // 누적 페이지 라인 (전경)
                          LineChart(
                            LineChartData(
                              lineBarsData: [
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
                                        const Color(0xFF5B7FFF).withOpacity(0.15),
                                        const Color(0xFF5B7FFF).withOpacity(0.0),
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
                              minY: 0,
                              maxY: (maxPage * 1.1).ceilToDouble(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 일별 상세 기록
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

  /// 플로팅 업데이트 버튼
  Widget _buildFloatingUpdateButton(bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _showUpdatePageDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7FFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: const Text(
              '현재 페이지 업데이트',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 목표일 변경 (컨펌 알럿 포함)
  void _showUpdateTargetDateDialogWithConfirm() async {
    final nextAttempt = _attemptCount + 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표일 변경'),
        content: Text(
          '목표일을 변경하시겠어요?\n$nextAttempt번째 도전으로 상태가 변경됩니다.',
          style: const TextStyle(height: 1.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7FFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _currentBook.targetDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (picked != null && mounted) {
        final updatedBook = _currentBook.copyWith(targetDate: picked);
        final result =
            await _bookService.updateBook(_currentBook.id!, updatedBook);

        if (result != null) {
          setState(() {
            _currentBook = result;
            _attemptCount = nextAttempt;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$nextAttempt번째 도전이 시작되었습니다!'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    }
  }
}

/// 드래그로 해제 가능한 전체보기 이미지 위젯
class _DraggableDismissImage extends StatefulWidget {
  final Animation<double> animation;
  final Uint8List imageBytes;

  const _DraggableDismissImage({
    required this.animation,
    required this.imageBytes,
  });

  @override
  State<_DraggableDismissImage> createState() => _DraggableDismissImageState();
}

class _DraggableDismissImageState extends State<_DraggableDismissImage> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);

    return FadeTransition(
      opacity: widget.animation,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.87 * opacity),
        body: GestureDetector(
          onVerticalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 100 ||
                details.velocity.pixelsPerSecond.dy.abs() > 500) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _dragOffset = 0;
                _isDragging = false;
              });
            }
          },
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
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
}

/// 드래그로 해제 가능한 네트워크 이미지 전체보기 위젯
class _DraggableDismissNetworkImage extends StatefulWidget {
  final Animation<double> animation;
  final String imageUrl;
  final String imageId;

  const _DraggableDismissNetworkImage({
    required this.animation,
    required this.imageUrl,
    required this.imageId,
  });

  @override
  State<_DraggableDismissNetworkImage> createState() =>
      _DraggableDismissNetworkImageState();
}

class _DraggableDismissNetworkImageState
    extends State<_DraggableDismissNetworkImage> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);

    return FadeTransition(
      opacity: widget.animation,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.87 * opacity),
        body: GestureDetector(
          onVerticalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 100 ||
                details.velocity.pixelsPerSecond.dy.abs() > 500) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _dragOffset = 0;
                _isDragging = false;
              });
            }
          },
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'book_image_${widget.imageId}',
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
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
}

/// 스티키 탭 바 델리게이트
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  const _StickyTabBarDelegate({
    required this.child,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 56; // 탭 바 높이

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: backgroundColor,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child || backgroundColor != oldDelegate.backgroundColor;
  }
}
