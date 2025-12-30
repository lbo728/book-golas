import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/book.dart';
import '../../../data/services/image_cache_manager.dart';
import '../../../data/services/book_service.dart';
import '../../../data/services/google_vision_ocr_service.dart';
import '../../core/ui/book_image_widget.dart';
import '../../core/ui/custom_snackbar.dart';

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
  late int _attemptCount; // 도전 횟수 (DB에서 로드)
  Map<String, bool> _dailyAchievements = {}; // 일차별 목표 달성 현황 (날짜: 성공/실패)
  bool _useMockProgressData = false; // 🎨 진행률 히스토리 목업 데이터 사용 (실제 데이터 연결 완료)

  // 페이지 카운터 & 프로그레스바 애니메이션
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  int _animatedCurrentPage = 0;
  double _animatedProgress = 0.0;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 캐싱: Future를 한번만 생성하여 재사용
  late Future<List<Map<String, dynamic>>> _bookImagesFuture;
  late Future<List<Map<String, dynamic>>> _progressHistoryFuture;

  // 로컬 캐시: 서버 데이터 로드 완료 후 로컬에서 관리
  List<Map<String, dynamic>>? _cachedImages;

  // 메모리에 수정된 텍스트 저장 (저장 버튼 누르기 전까지 유지)
  final Map<String, String> _editedTexts = {};

  // 인상적인 페이지 선택 모드
  bool _isSelectionMode = false;
  final Set<String> _selectedImageIds = {};

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _attemptCount = widget.book.attemptCount;
    _todayStartPage = _currentBook.startDate.day;
    _todayTargetPage = _currentBook.targetDate.day;
    _tabController = TabController(length: 3, vsync: this);
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
    _scrollController.dispose();
    super.dispose();
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
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact Book Header (Dashboard Style)
                          _buildCompactBookHeader(isDark),
                          const SizedBox(height: 10),

                          // Compact Reading Schedule (시작일/목표일)
                          _buildCompactReadingSchedule(isDark),
                          const SizedBox(height: 12),

                          // Dashboard Progress (2-Column)
                          _buildDashboardProgress(isDark),
                          const SizedBox(height: 12),

                          // Compact Streak Row (7일 도트)
                          _buildCompactStreakRow(isDark),
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
                    _buildDetailTab(isDark),
                  ],
                ),
              ),
            ),
          ),
          // Linear 스타일 리퀴드 글래스 플로팅 바 (키보드가 열리면 완료 버튼으로 교체)
          if (isKeyboardOpen)
            _buildKeyboardDoneButton(isDark)
          else
            _buildLiquidGlassFloatingBar(isDark),
        ],
      ),
    );
  }

  /// Compact Hero Section: Circular Progress + D-day (Radial Progress Indicator)
  Widget _buildCompactHeroSection(bool isDark) {
    final progressPercent = (_animatedProgress * 100).toStringAsFixed(0);
    final isOverdue = _daysLeft < 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress (Radial Progress Indicator)
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: _animatedProgress.clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFEEF2FF),
                      progressColor: const Color(0xFF5B7FFF),
                    ),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '진행률',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // D-day
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0xFFFFEBEB)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverdue ? 'D+${_daysLeft.abs()}' : 'D-$_daysLeft',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isOverdue
                          ? const Color(0xFFE53935)
                          : const Color(0xFF5B7FFF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Pages
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF888888),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_animatedCurrentPage',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      ' / ${_currentBook.totalPages}p',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Pages remaining
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF888888),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_pagesLeft',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      ' 페이지 남음',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF888888),
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
          // Book Cover (탭하면 전체보기)
          GestureDetector(
            onTap: () {
              if (_currentBook.imageUrl != null &&
                  _currentBook.imageUrl!.isNotEmpty) {
                _showFullScreenImage(
                  'book_cover_${_currentBook.id}',
                  _currentBook.imageUrl!,
                );
              }
            },
            child: Hero(
              tag: 'book_cover_${_currentBook.id}',
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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

                // Title (탭하면 전체 제목 표시)
                GestureDetector(
                  onTap: () => _showFullTitleDialog(_currentBook.title),
                  child: Text(
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
                // 서점에서 보기 버튼
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showBookstoreSelectSheet(_currentBook.title),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_up_right_square,
                        size: 14,
                        color: const Color(0xFF5B7FFF),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '서점에서 보기',
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
          ),
        ],
      ),
    );
  }

  /// 컴팩트 독서 일정 Row (시작일/목표일 + 변경 버튼)
  Widget _buildCompactReadingSchedule(bool isDark) {
    final startDateStr = _currentBook.startDate
        .toString()
        .substring(0, 10)
        .replaceAll('-', '.');
    final targetDateStr = _currentBook.targetDate
        .toString()
        .substring(0, 10)
        .replaceAll('-', '.');
    // 총 일수 계산
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
          // 시작일 (라벨 포함)
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
          // 목표일 (라벨 포함)
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
          // 총 일수 표시
          Text(
            '($totalDays일)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          // N번째 도전 뱃지
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
          // 변경 버튼 (연필 아이콘)
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
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                cacheManager: BookImageCacheManager.instance,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
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
          // 진행률 히스토리 새로고침
          _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
        });

        // 최상단으로 스크롤
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

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedImageIds.length;

    // 삭제 확인 다이얼로그
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

                        // 선택된 항목들 삭제
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
      // 인상적인 페이지 탭으로 이동 후 스크롤 상단으로
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
                              onPressed: isUploading || textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null
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
                                  color: (isUploading || textController.text.isEmpty || pageController.text.isEmpty || pageValidationError != null)
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

  /// 진행률 히스토리 스켈레톤 빌더
  Widget _buildProgressHistorySkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 차트 카드 스켈레톤
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
                  // 헤더 스켈레톤
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
                  // 범례 스켈레톤
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
                  // 차트 영역 스켈레톤
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
            // 독서 상태 분석 스켈레톤
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
            // 일별 기록 헤더 스켈레톤
            Container(
              width: 100,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // 일별 기록 카드 스켈레톤 (3개)
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

  /// 독서 상태 분석 및 격려 메시지 빌더
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
                          '$_attemptCount번째 도전',
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

  /// 독서 상태 분석 로직
  Map<String, dynamic> _analyzeReadingState(List<Map<String, dynamic>> progressData) {
    final progressPercent = _progressPercentage;
    final daysLeft = _daysLeft;
    final totalDays = _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;
    final elapsedDays = DateTime.now().difference(_currentBook.startDate).inDays;
    final readingDays = progressData.length;

    // 예상 완료율 vs 실제 완료율
    final expectedProgress = elapsedDays > 0
        ? (elapsedDays / totalDays * 100).clamp(0, 100)
        : 0.0;
    final progressDiff = progressPercent - expectedProgress;

    // 완독 상태
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

    // 마감 초과
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

    // 아주 잘하고 있음 (예상보다 20% 이상 앞서감)
    if (progressDiff > 20) {
      return {
        'emoji': '🚀',
        'title': '놀라운 속도예요!',
        'message': '예상보다 훨씬 빠르게 읽고 있어요. 이 페이스면 일찍 완독할 수 있겠어요!',
        'color': const Color(0xFF5B7FFF),
      };
    }

    // 잘하고 있음 (예상보다 5-20% 앞서감)
    if (progressDiff > 5) {
      return {
        'emoji': '✨',
        'title': '순조롭게 진행 중!',
        'message': '계획보다 앞서가고 있어요. 이대로만 하면 목표 달성 확실해요!',
        'color': const Color(0xFF10B981),
      };
    }

    // 적정 페이스 (예상과 비슷)
    if (progressDiff > -5) {
      return {
        'emoji': '📖',
        'title': '계획대로 진행 중',
        'message': '꾸준히 읽고 있어요. 오늘도 조금씩 읽어볼까요?',
        'color': const Color(0xFF5B7FFF),
      };
    }

    // 약간 뒤처짐 (5-15% 뒤처짐)
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

    // 많이 뒤처짐 (15% 이상 뒤처짐)
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

  /// 컴팩트 책 헤더 (Dashboard 스타일)
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
          // 작은 표지 (탭하면 전체보기)
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

          // 제목 + 저자 + 상태
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

  /// 대시보드 스타일 진행률 (2-Column)
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
          // 왼쪽: 원형 진행률
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
                          painter: _CircularProgressPainter(
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

          // 구분선
          Container(
            width: 1,
            height: 100,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),

          // 오른쪽: D-day + 남은 페이지 + 오늘 목표
          Expanded(
            child: Column(
              children: [
                // D-day (3일 이하일 때 레드)
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
                // 남은 페이지 ("OO페이지 남았어요" 형식, 페이지 수 볼드)
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
                // 오늘 목표 (남은 페이지 / 남은 일수) + 변경 버튼
                Builder(
                  builder: (context) {
                    final dailyTarget = _daysLeft > 0
                        ? (_pagesLeft / _daysLeft).ceil()
                        : _pagesLeft;
                    if (dailyTarget > 0) {
                      return GestureDetector(
                        onTap: _showDailyTargetChangeDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '오늘 목표: ${dailyTarget}p',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.pencil,
                                size: 11,
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

  /// 키보드 완료 버튼 (리퀴드 글래스 스타일)
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

  /// Linear 스타일 리퀴드 글래스 플로팅 바 (분리형)
  Widget _buildLiquidGlassFloatingBar(bool isDark) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: SafeArea(
        child: Row(
          children: [
            // 페이지 업데이트 버튼 (메인 바 - 분리됨)
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

            // + 버튼 (완전 분리된 원형)
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

  /// 상세 탭 (독서 일정 + 풀 Contribution Graph)
  Widget _buildDetailTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 독서 일정 섹션
          _buildReadingScheduleCard(isDark),
          const SizedBox(height: 16),

          // 목표 달성 현황 (풀 Contribution Graph)
          _buildTodayGoalCardWithStamps(isDark),
        ],
      ),
    );
  }

  /// 컴팩트 스트릭 Row (최근 7일 도트 + N일 연속 + 요일 라벨)
  Widget _buildCompactStreakRow(bool isDark) {
    // 요일 이름 (한글)
    const dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    // 최근 7일 달성 현황 계산
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

    // 연속 달성일 계산
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
          // 1행: 최근 7일 도트 + 요일 라벨 (크게)
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
                    // 요일 라벨
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
                    // 도트
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
          // 2행: 불꽃 아이콘 + 스트릭 텍스트
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

  /// 목표 달성 현황 카드 (Contribution Graph 스타일)
  Widget _buildTodayGoalCardWithStamps(bool isDark) {
    final totalDays =
        _currentBook.targetDate.difference(_currentBook.startDate).inDays + 1;
    final now = DateTime.now();
    final todayIndex = now.difference(_currentBook.startDate).inDays;

    // 달성률 계산
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
          // 헤더 with 달성률
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
              // 달성률 badge
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

          // Contribution Graph 스타일 그리드
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

          // Legend
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

  /// 탭 바만 반환 (스티키 헤더용) - 3탭
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
          // 슬라이딩 인디케이터 (스와이프 제스처와 동기화)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                final indicatorWidth = tabWidth * 0.5; // 탭 너비의 50%
                return AnimatedBuilder(
                  animation: _tabController.animation!,
                  builder: (context, child) {
                    final animValue = _tabController.animation!.value;
                    // 각 탭의 중앙 위치 계산
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

  void _showReplaceImageOptionsOverModal({
    required String imageId,
    required String currentText,
    required VoidCallback onReplaced,
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
                  _pickImageAndExtractText(
                    ImageSource.camera,
                    (imageBytes, ocrText, pageNumber) async {
                      await _replaceImage(imageId, imageBytes, ocrText.isEmpty ? currentText : ocrText, pageNumber);
                      onReplaced();
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
                  _pickImageAndExtractText(
                    ImageSource.gallery,
                    (imageBytes, ocrText, pageNumber) async {
                      await _replaceImage(imageId, imageBytes, ocrText.isEmpty ? currentText : ocrText, pageNumber);
                      onReplaced();
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
        CustomSnackbar.show(
          context,
          message: '이미지가 교체되었습니다',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '이미지 교체 실패',
          type: SnackbarType.error,
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
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '인상적인 페이지',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (pageNumber != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'p.$pageNumber',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
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
                                          // 캐시 무효화 및 새로운 데이터 로드
                                          _cachedImages = null;
                                          _bookImagesFuture = fetchBookImages(_currentBook.id!);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            // setState로 리스트 갱신 트리거
                                            if (mounted) {
                                              setState(() {});
                                            }
                                            CustomSnackbar.show(
                                              this.context,
                                              message: '텍스트가 저장되었습니다',
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
                                                // 모달은 유지하고 그 위에 바텀시트 표시
                                                _showReplaceImageOptionsOverModal(
                                                  imageId: imageId,
                                                  currentText: textController.text,
                                                  onReplaced: () {
                                                    // 교체 완료 후 모달 닫기
                                                    Navigator.pop(context);
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
                                              CustomSnackbar.show(context, message: '텍스트가 복사되었습니다.', rootOverlay: true);
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
                                                    CustomSnackbar.show(context, message: '텍스트가 복사되었습니다.', rootOverlay: true);
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
            // 선택 모드 헤더
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
                    const SizedBox(),
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
            final isSelected = _selectedImageIds.contains(imageId);

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
                      // 선택 모드: 체크박스 / 일반 모드: 화살표
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
                                  '$_attemptCount번째 도전',
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chartWidth = constraints.maxWidth - 40; // left reserved
                          final barWidth = data.length > 1
                              ? (chartWidth / data.length * 0.4).clamp(4.0, 16.0)
                              : 16.0;

                          // 일일 페이지 스케일을 누적 페이지 스케일에 맞춤
                          final scaledMaxY = (maxPage * 1.1).ceilToDouble();
                          final barScaleFactor = scaledMaxY / (maxDailyPage > 0 ? maxDailyPage * 1.5 : 1);

                          return LineChart(
                            LineChartData(
                              lineBarsData: [
                                // 일일 페이지 막대 (스케일 조정된 값)
                                ...dailyPagesSpots.map((spot) {
                                  final scaledY = spot.y * barScaleFactor * 0.3; // 막대 높이를 차트 하단 30%로 제한
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
                                // 누적 페이지 라인
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
              // 독서 상태 분석 메시지
              _buildReadingStateAnalysis(isDark, data),
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

  /// 전체 제목 표시 바텀시트 (복사/서점에서 보기 기능 포함)
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

  /// 서점에서 검색할 제목 추출 (하이픈 앞까지)
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

  /// 서점 선택 바텀시트
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

  /// 서점 버튼 위젯
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

  /// 일일 목표 페이지 변경 (수평 다이얼 + 스케줄 테이블)
  void _showDailyTargetChangeDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 현재 일일 목표 계산
    final currentDailyTarget = _daysLeft > 0
        ? (_pagesLeft / _daysLeft).ceil()
        : _pagesLeft;

    int newDailyTarget = currentDailyTarget;
    double sheetExtent = 0.6;
    final scrollController = ScrollController();
    final wheelController = FixedExtentScrollController(initialItem: newDailyTarget - 1);

    // 스케줄 계산 함수 (점차 줄어드는 방식)
    List<Map<String, dynamic>> calculateSchedule(int dailyTarget) {
      final schedule = <Map<String, dynamic>>[];
      int remainingPages = _pagesLeft;
      DateTime currentDate = DateTime.now();
      final targetDate = _currentBook.targetDate;

      while (remainingPages > 0 && !currentDate.isAfter(targetDate.add(const Duration(days: 30)))) {
        int pagesToRead;
        if (schedule.isEmpty) {
          pagesToRead = dailyTarget;
        } else {
          final daysRemaining = targetDate.difference(currentDate).inDays + 1;
          if (daysRemaining > 0) {
            pagesToRead = (remainingPages / daysRemaining).ceil();
          } else {
            pagesToRead = remainingPages;
          }
        }
        pagesToRead = pagesToRead.clamp(1, remainingPages);

        final weekday = ['월', '화', '수', '목', '금', '토', '일'][currentDate.weekday - 1];

        schedule.add({
          'date': currentDate,
          'weekday': weekday,
          'pages': pagesToRead,
          'isToday': currentDate.day == DateTime.now().day &&
              currentDate.month == DateTime.now().month &&
              currentDate.year == DateTime.now().year,
        });

        remainingPages -= pagesToRead;
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return schedule;
    }

    // 캐시된 스케줄 (dailyTarget 변경 시에만 재계산)
    var cachedSchedule = calculateSchedule(currentDailyTarget);
    int lastCalculatedTarget = currentDailyTarget;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // dailyTarget이 변경된 경우에만 재계산
            if (newDailyTarget != lastCalculatedTarget) {
              cachedSchedule = calculateSchedule(newDailyTarget);
              lastCalculatedTarget = newDailyTarget;
            }
            final schedule = cachedSchedule;
            final daysToComplete = schedule.length;
            final targetDate = _currentBook.targetDate;
            final canFinishOnTime = daysToComplete <= _daysLeft;
            final maxPages = schedule.isNotEmpty
                ? schedule.map((s) => s['pages'] as int).reduce((a, b) => a > b ? a : b)
                : newDailyTarget;

            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setModalState(() {
                  sheetExtent = notification.extent;
                });
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 헤더
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.book,
                                            color: Color(0xFF10B981),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '일일 목표 페이지 변경',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '$_pagesLeft페이지',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: ' 남았어요 · D-$_daysLeft',
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
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),
                                    // 수평 다이얼 피커
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 70,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFF10B981),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          RotatedBox(
                                            quarterTurns: 3,
                                            child: ListWheelScrollView.useDelegate(
                                              controller: wheelController,
                                              itemExtent: 70,
                                              perspective: 0.005,
                                              diameterRatio: 1.5,
                                              physics: const FixedExtentScrollPhysics(),
                                              onSelectedItemChanged: (index) {
                                                setModalState(() {
                                                  newDailyTarget = index + 1;
                                                });
                                              },
                                              childDelegate: ListWheelChildBuilderDelegate(
                                                childCount: _pagesLeft.clamp(1, 200),
                                                builder: (context, index) {
                                                  final value = index + 1;
                                                  final isSelected = value == newDailyTarget;
                                                  return GestureDetector(
                                                    onTap: () {
                                                      wheelController.animateToItem(
                                                        index,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                      );
                                                    },
                                                    child: RotatedBox(
                                                      quarterTurns: 1,
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              '$value',
                                                              style: TextStyle(
                                                                fontSize: isSelected ? 32 : 20,
                                                                fontWeight: isSelected
                                                                    ? FontWeight.bold
                                                                    : FontWeight.w400,
                                                                color: isSelected
                                                                    ? const Color(0xFF10B981)
                                                                    : (isDark
                                                                        ? Colors.grey[500]
                                                                        : Colors.grey[400]),
                                                              ),
                                                            ),
                                                            if (isSelected)
                                                              Text(
                                                                '페이지/일',
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
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // 목표 달성 가능 여부 표시
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: canFinishOnTime
                                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                            : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            canFinishOnTime
                                                ? CupertinoIcons.checkmark_circle
                                                : CupertinoIcons.exclamationmark_circle,
                                            color: canFinishOnTime
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFFF6B6B),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              canFinishOnTime
                                                  ? '${targetDate.month}/${targetDate.day}까지 완료 가능!'
                                                  : '목표일까지 $daysToComplete일 필요 (${daysToComplete - _daysLeft}일 초과)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: canFinishOnTime
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFFF6B6B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // 예상 스케줄 헤더
                                    Text(
                                      '예상 스케줄',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 스케줄 리스트 (항상 펼쳐져 있음)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= schedule.length) return null;
                              final item = schedule[index];
                              final date = item['date'] as DateTime;
                              final isToday = item['isToday'] as bool;
                              final pages = item['pages'] as int;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? const Color(0xFF5B7FFF).withValues(alpha: 0.1)
                                      : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]),
                                  borderRadius: index == 0
                                      ? const BorderRadius.vertical(top: Radius.circular(12))
                                      : (index == schedule.length - 1
                                          ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                          : null),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${date.month}/${date.day} (${item['weekday']})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                                          color: isToday
                                              ? const Color(0xFF5B7FFF)
                                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: pages / maxPages,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${pages}p',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: schedule.length,
                          ),
                        ),
                        // 버튼 영역
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              24,
                              24,
                              24 + MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Row(
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
                                      // DB에 일일 목표 페이지 업데이트
                                      try {
                                        await Supabase.instance.client
                                            .from('books')
                                            .update({'daily_target_pages': newDailyTarget})
                                            .eq('id', _currentBook.id!);
                                        setState(() {
                                          _currentBook = _currentBook.copyWith(
                                            dailyTargetPages: newDailyTarget,
                                          );
                                        });
                                        if (mounted) {
                                          CustomSnackbar.show(
                                            context,
                                            message: '오늘 목표: ${newDailyTarget}p로 변경되었습니다',
                                            type: SnackbarType.success,
                                            bottomOffset: 100,
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          CustomSnackbar.show(
                                            context,
                                            message: '목표 변경에 실패했습니다',
                                            type: SnackbarType.error,
                                            bottomOffset: 100,
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '변경',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
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
                  // 선택된 날짜 표시 + D-day
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
                  // 한국식 다이얼 피커 (년/월/일)
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

      // 스크롤 최상단으로
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
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        cacheManager: BookImageCacheManager.instance,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[800],
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
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

/// Circular Progress Painter (Radial Progress Indicator)
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
