import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/book_list/view_model/book_list_view_model.dart';
import 'package:book_golas/ui/book_list/widgets/book_list_card.dart';
import 'package:book_golas/ui/book_list/widgets/book_list_skeleton.dart';
import 'package:book_golas/ui/book_list/widgets/planned_book_card.dart';
import 'package:book_golas/ui/book_list/widgets/paused_book_card.dart';
import 'package:book_golas/ui/book_list/widgets/completed_book_card.dart';

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
    _tabController = TabController(
        length: 5, vsync: this, initialIndex: vm.selectedTabIndex);
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
        return Column(
          children: [
            _buildTabBar(vm, isDark),
            Expanded(
              child: _buildBody(vm, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BookListViewModel vm, bool isDark) {
    final selectedTabIndex = vm.selectedTabIndex;
    return Container(
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
                    _buildScrollableTabItem(
                        '읽을 예정', 1, selectedTabIndex, isDark),
                    _buildScrollableTabItem(
                        '독서 중', 2, selectedTabIndex, isDark),
                    _buildScrollableTabItem('완독', 3, selectedTabIndex, isDark),
                    _buildScrollableTabItem(
                        '다시 읽을 책', 4, selectedTabIndex, isDark),
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
    );
  }

  Widget _buildBody(BookListViewModel vm, bool isDark) {
    if (vm.isLoading && vm.books.isEmpty) {
      return const BookListSkeleton();
    }

    if (vm.errorMessage != null) {
      return _buildErrorState(isDark);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllBooksTab(vm, isDark),
        _buildPlannedBooksTab(vm, isDark),
        _buildReadingBooksTab(vm, isDark),
        _buildCompletedBooksTab(vm, isDark),
        _buildPausedBooksTab(vm, isDark),
      ],
    );
  }

  Widget _buildScrollableTabItem(
      String title, int index, int selectedTabIndex, bool isDark) {
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

  Widget _buildErrorState(bool isDark) {
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

  Widget _buildPlannedBooksTab(BookListViewModel vm, bool isDark) {
    final plannedBooks = vm.plannedBooks;

    if (plannedBooks.isEmpty) {
      return _buildEmptyState('읽을 예정인 책이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: plannedBooks
            .map((book) => PlannedBookCard(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPausedBooksTab(BookListViewModel vm, bool isDark) {
    final pausedBooks = vm.pausedBooks;

    if (pausedBooks.isEmpty) {
      return _buildEmptyState('잠시 쉬어가는 책이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: pausedBooks
            .map((book) => PausedBookCard(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
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
      return _buildEmptyState('아직 시작한 독서가 없습니다');
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
            ...(vm.showAllCurrentBooks ? readingBooks : readingBooks.take(3))
                .map((book) => BookListCard(
                      book: book,
                      onTap: () => _navigateToBookDetail(book),
                    )),
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
          ...allBooks.map((book) => BookListCard(
                book: book,
                onTap: () => _navigateToBookDetail(book),
              )),
        ],
      ),
    );
  }

  Widget _buildReadingBooksTab(BookListViewModel vm, bool isDark) {
    final readingBooks = vm.readingBooks;

    if (readingBooks.isEmpty) {
      return _buildEmptyState('현재 읽고 있는 책이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: readingBooks
            .map((book) => BookListCard(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCompletedBooksTab(BookListViewModel vm, bool isDark) {
    final completedBooks = vm.completedBooks;

    if (completedBooks.isEmpty) {
      return _buildEmptyState('완독한 책이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(vm),
      color: const Color(0xFF5B7FFF),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        children: completedBooks
            .map((book) => CompletedBookCard(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ))
            .toList(),
      ),
    );
  }

  void _navigateToBookDetail(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
    if (mounted) {
      context.read<BookListViewModel>().refresh();
    }
  }
}
