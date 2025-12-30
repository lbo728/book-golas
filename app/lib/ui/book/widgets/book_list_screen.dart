import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/book.dart';
import '../../core/ui/book_image_widget.dart';
import 'book_detail_screen_redesigned.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _showAllCurrentBooks = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('독서 목록'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '전체',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _selectedTabIndex == 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedTabIndex == 0
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '독서 중',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _selectedTabIndex == 1
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedTabIndex == 1
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '완독',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _selectedTabIndex == 2
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedTabIndex == 2
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 슬라이딩 인디케이터 (스와이프와 실시간 동기화)
                Positioned(
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _tabController.animation!,
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tabWidth = screenWidth / 3;
                      final animationValue = _tabController.animation!.value;
                      return Transform.translate(
                        offset: Offset(tabWidth * animationValue, 0),
                        child: Container(
                          width: tabWidth,
                          height: 2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: userId == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('books')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                // 초기 로딩 중이고 데이터가 없을 때만 스켈레톤 표시
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildSkeletonList(isDark);
                }

                // 에러 발생 시 재시도 가능한 UI 표시
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '데이터를 불러올 수 없습니다',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '네트워크 연결을 확인해주세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final rows = snapshot.data ?? [];
                final allBooks = rows.map((e) => Book.fromJson(e)).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllBooksTab(allBooks, isDark),
                    _buildReadingBooksTab(allBooks, isDark),
                    _buildCompletedBooksTab(allBooks, isDark),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '아직 시작한 독서가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllBooksTab(List<Book> allBooks, bool isDark) {
    final readingBooks = allBooks.where((book) => book.currentPage < book.totalPages).toList();

    if (allBooks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: [
          if (readingBooks.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '현재 읽고 있는 책',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (readingBooks.length > 3)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllCurrentBooks = !_showAllCurrentBooks;
                      });
                    },
                    child: Text(
                      _showAllCurrentBooks ? '접기' : '더보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_showAllCurrentBooks
                ? readingBooks
                : readingBooks.take(3)).map((book) => _buildBookCard(book)),
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 24),
          ],
          Text(
            '전체 독서 목록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...allBooks.map((book) => _buildBookCard(book)),
        ],
      ),
    );
  }

  Widget _buildReadingBooksTab(List<Book> allBooks, bool isDark) {
    final readingBooks = allBooks.where((book) => book.currentPage < book.totalPages).toList();

    if (readingBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '현재 읽고 있는 책이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: readingBooks.map((book) => _buildBookCard(book)).toList(),
      ),
    );
  }

  Widget _buildCompletedBooksTab(List<Book> allBooks, bool isDark) {
    final completedBooks = allBooks.where((book) => book.currentPage >= book.totalPages).toList();

    if (completedBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '완독한 책이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: completedBooks.map((book) => _buildBookCard(book)).toList(),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(book.targetDate.year, book.targetDate.month, book.targetDate.day);
    final daysLeft = target.difference(today).inDays;
    final totalDays = book.targetDate.difference(book.startDate).inDays;
    final daysPassed = DateTime.now().difference(book.startDate).inDays;
    final progressPercentage =
        totalDays > 0 ? (daysPassed / totalDays * 100).clamp(0, 100) : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageProgress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = book.currentPage >= book.totalPages && book.totalPages > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreenRedesigned(book: book),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BookImageWidget(
                  imageUrl: book.imageUrl,
                  iconSize: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // D-day 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: daysLeft < 0
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : (isCompleted
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : const Color(0xFF5B7FFF).withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysLeft >= 0 ? 'D-$daysLeft' : 'D+${daysLeft.abs()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: daysLeft < 0
                                ? const Color(0xFFEF4444)
                                : (isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF5B7FFF)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 페이지 정보
                      Text(
                        '${book.currentPage}/${book.totalPages}페이지',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pageProgress,
                            backgroundColor: isDark
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF5B7FFF),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pageProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF5B7FFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[400] : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
      itemCount: 3,
      itemBuilder: (context, index) => _buildSkeletonCard(isDark, index),
    );
  }

  Widget _buildSkeletonCard(bool isDark, [int index = 0]) {
    final titleWidths = [double.infinity, 180.0, 220.0];
    final subtitleWidths = [140.0, 100.0, 160.0];

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: titleWidths[index % 3],
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 24,
                        width: 52,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 14,
                        width: subtitleWidths[index % 3],
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 12,
                        width: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
