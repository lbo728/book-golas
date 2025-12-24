import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../domain/models/book.dart';
import '../../../data/services/book_service.dart';
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
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  late Book _currentBook;
  int? _todayStartPage;
  int? _todayTargetPage;
  late TabController _tabController;
  int _attemptCount = 1; // 도전 횟수
  Map<String, bool> _dailyAchievements = {}; // 일차별 목표 달성 현황 (날짜: 성공/실패)
  bool _useMockProgressData = true; // 🎨 진행률 히스토리 목업 데이터 사용

  // 캐싱: Future를 한번만 생성하여 재사용
  late Future<List<Map<String, dynamic>>> _bookImagesFuture;
  late Future<List<Map<String, dynamic>>> _progressHistoryFuture;

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

    // Future를 initState에서 한번만 생성 (캐싱)
    _bookImagesFuture = fetchBookImages(_currentBook.id!);
    _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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

                  // Tabbed Section: Memorable Pages + Progress History
                  _buildTabbedSection(isDark),
                  const SizedBox(height: 20),
                ],
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
                      '${_progressPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentBook.currentPage}/${_currentBook.totalPages}p',
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
                        widthFactor: _progressPercentage / 100,
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
              onPressed: _showAddImageBottomSheet,
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
                return GestureDetector(
                  onLongPress: () => _confirmDeleteImage(
                    image['id'] as String,
                    image['image_url'] as String,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      image['image_url'] as String,
                      fit: BoxFit.cover,
                    ),
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
      text: _currentBook.currentPage.toString(),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              Text(
                '총 ${_currentBook.totalPages} 페이지',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '현재 페이지',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF5B7FFF),
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
                      onPressed: () {
                        final page = int.tryParse(controller.text);
                        if (page != null &&
                            page >= 0 &&
                            page <= _currentBook.totalPages) {
                          Navigator.pop(context);
                          _updateCurrentPage(page);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('올바른 페이지 번호를 입력해주세요.'),
                              backgroundColor: Colors.red,
                            ),
                          );
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
                        '업데이트',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
  }

  Future<void> _updateCurrentPage(int newPage) async {
    try {
      final updatedBook =
          await _bookService.updateCurrentPage(_currentBook.id!, newPage);
      if (updatedBook != null) {
        setState(() {
          _currentBook = updatedBook;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('페이지가 업데이트되었습니다.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
        .select('id, image_url')
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => {
              'id': e['id'] as String,
              'image_url': e['image_url'] as String,
            })
        .where((e) => e['image_url']!.isNotEmpty)
        .toList();
  }

  Future<void> _deleteBookImage(String imageId, String imageUrl) async {
    final storage = Supabase.instance.client.storage;
    final bucketPath =
        imageUrl.split('/storage/v1/object/public/book-images/').last;
    await storage.from('book-images').remove([bucketPath]);
    await Supabase.instance.client
        .from('book_images')
        .delete()
        .eq('id', imageId);

    // 캐시 새로고침
    setState(() {
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });
  }

  void _confirmDeleteImage(String imageId, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('정말 이미지를 삭제하시겠습니까?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBookImage(imageId, imageUrl);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadBookImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storage = Supabase.instance.client.storage;
    await storage.from('book-images').uploadBinary(fileName, bytes,
        fileOptions: const FileOptions(upsert: true));

    final publicUrl = storage.from('book-images').getPublicUrl(fileName);

    await Supabase.instance.client.from('book_images').insert({
      'book_id': _currentBook.id,
      'image_url': publicUrl,
      'caption': '',
    });

    // 캐시 새로고침
    setState(() {
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });
  }

  void _showAddImageBottomSheet() {
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
                      color: const Color(0xFF5B7FFF).withOpacity(0.1),
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
                          await _pickAndUploadBookImage(ImageSource.camera);
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
                      color: const Color(0xFF5B7FFF).withOpacity(0.1),
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
                    await _pickAndUploadBookImage(ImageSource.gallery);
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

  /// 탭 섹션: 인상적인 페이지 + 진행률 히스토리
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

  void _showFullScreenImage(String imageId, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Hero(
                        tag: 'book_image_$imageId',
                        child: Image.network(
                          imageUrl,
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
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmDeleteImage(imageId, imageUrl);
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '화면을 탭하면 닫힙니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildMemorablePagesTab(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookImagesFuture, // 캐시된 Future 사용
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final images = snapshot.data ?? [];

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
                  onPressed: _showAddImageBottomSheet,
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: const Text('사진 추가'),
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

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // 추가 버튼
              return GestureDetector(
                onTap: _showAddImageBottomSheet,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final image = images[index - 1];
            final imageId = image['id'] as String;
            final imageUrl = image['image_url'] as String;
            return GestureDetector(
              onTap: () => _showFullScreenImage(imageId, imageUrl),
              onLongPress: () => _confirmDeleteImage(imageId, imageUrl),
              child: Hero(
                tag: 'book_image_$imageId',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
