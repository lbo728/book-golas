import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/core/widgets/book_image_widget.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/book_list/view_model/book_list_view_model.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<BookListViewModel>();
    _tabController = TabController(length: 4, vsync: this, initialIndex: vm.selectedTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        vm.setSelectedTabIndex(_tabController.index);
      }
    });

    vm.addListener(_syncTabController);
  }

  void _syncTabController() {
    final vm = context.read<BookListViewModel>();
    if (_tabController.index != vm.selectedTabIndex) {
      _tabController.animateTo(vm.selectedTabIndex);
    }
  }

  @override
  void dispose() {
    context.read<BookListViewModel>().removeListener(_syncTabController);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh(BookListViewModel vm) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await vm.refresh();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BookListViewModel>(
      builder: (context, vm, _) {
        final selectedTabIndex = vm.selectedTabIndex;

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
                child: SizedBox(
                  height: 50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              _buildScrollableTabItem('전체', 0, selectedTabIndex, isDark),
                              _buildScrollableTabItem('독서 중', 1, selectedTabIndex, isDark),
                              _buildScrollableTabItem('완독', 2, selectedTabIndex, isDark),
                              _buildScrollableTabItem('다시 읽을 책', 3, selectedTabIndex, isDark),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _tabController.animation!,
                          builder: (context, child) {
                            const tabWidth = 100.0;
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _buildBody(vm, isDark),
        );
      },
    );
  }

  Widget _buildBody(BookListViewModel vm, bool isDark) {
    if (vm.isLoading && vm.books.isEmpty) {
      return _buildSkeletonList(isDark);
    }

    if (vm.errorMessage != null) {
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllBooksTab(vm, isDark),
        _buildReadingBooksTab(vm, isDark),
        _buildCompletedBooksTab(vm, isDark),
        _buildRereadBooksTab(vm, isDark),
      ],
    );
  }

  Widget _buildScrollableTabItem(String title, int index, int selectedTabIndex, bool isDark) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: SizedBox(
        width: 100,
        height: 48,
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRereadBooksTab(BookListViewModel vm, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '다시 읽을 책',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '준비 중입니다',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingEmptyState() {
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

  Widget _buildCompletedEmptyState() {
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

  Widget _buildAllBooksTab(BookListViewModel vm, bool isDark) {
    final allBooks = vm.books;
    final readingBooks = vm.readingBooks;

    if (allBooks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
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
                    onTap: () => vm.toggleShowAllCurrentBooks(),
                    child: Text(
                      vm.showAllCurrentBooks ? '접기' : '더보기',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...(vm.showAllCurrentBooks
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

  Widget _buildReadingBooksTab(BookListViewModel vm, bool isDark) {
    final readingBooks = vm.readingBooks;

    if (readingBooks.isEmpty) {
      return _buildReadingEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: readingBooks.map((book) => _buildBookCard(book)).toList(),
      ),
    );
  }

  Widget _buildCompletedBooksTab(BookListViewModel vm, bool isDark) {
    final completedBooks = vm.completedBooks;

    if (completedBooks.isEmpty) {
      return _buildCompletedEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _PressableBookCard(
      book: book,
      isDark: isDark,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          ),
        );
        if (mounted) {
          context.read<BookListViewModel>().refresh();
        }
      },
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

class _PressableBookCard extends StatefulWidget {
  final Book book;
  final bool isDark;
  final VoidCallback onTap;

  const _PressableBookCard({
    required this.book,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PressableBookCard> createState() => _PressableBookCardState();
}

class _PressableBookCardState extends State<_PressableBookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _brightnessAnimation;
  final GlobalKey _cardKey = GlobalKey();
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _brightnessAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onTap();
          }
        });
      }
    });
  }

  void _onTapCancel() {
    // onTapCancel이 onLongPressStart보다 먼저 호출되므로
    // 잠시 대기 후 _isLongPressing 체크
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_isLongPressing && mounted) {
        _controller.reverse();
      }
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _isLongPressing = true;
    HapticFeedback.mediumImpact();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isLongPressing = false;
    _controller.reverse();

    final RenderBox? renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final isInsideCard = localPosition.dx >= 0 &&
          localPosition.dx <= renderBox.size.width &&
          localPosition.dy >= 0 &&
          localPosition.dy <= renderBox.size.height;

      if (isInsideCard) {
        HapticFeedback.lightImpact();
        widget.onTap();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isDark = widget.isDark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(book.targetDate.year, book.targetDate.month, book.targetDate.day);
    final daysLeft = target.difference(today).inDays;
    final pageProgress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = book.currentPage >= book.totalPages && book.totalPages > 0;

    return GestureDetector(
      key: _cardKey,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              foregroundDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _brightnessAnimation.value),
                borderRadius: BorderRadius.circular(8),
              ),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
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
            ),
          );
        },
      ),
    );
  }
}
