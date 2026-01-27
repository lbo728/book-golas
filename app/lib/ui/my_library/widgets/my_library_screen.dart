import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/my_library/view_model/my_library_view_model.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';
import 'package:book_golas/ui/core/widgets/liquid_glass_tab_bar.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/book_list/widgets/book_list_card.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyLibraryViewModel>().loadBooks();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context
          .read<MyLibraryViewModel>()
          .setSelectedTabIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('나의 서재'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Selector<MyLibraryViewModel, (int, int)>(
            selector: (_, vm) =>
                (vm.allBooks.length, vm.booksWithReview.length),
            builder: (context, counts, _) {
              final (allCount, reviewCount) = counts;
              return LiquidGlassTabBar(
                controller: _tabController,
                tabs: ['전체 ($allCount)', '독후감 ($reviewCount)'],
              );
            },
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllBooksTab(isDark),
                _buildReviewBooksTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Consumer<MyLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.availableYears.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                '전체',
                vm.selectedYear == null,
                isDark,
                () => vm.setSelectedYear(null),
              ),
              ...vm.availableYears.map(
                (year) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildFilterChip(
                    '$year년',
                    vm.selectedYear == year,
                    isDark,
                    () => vm.setSelectedYear(year),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildAllBooksTab(bool isDark) {
    return Consumer<MyLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = vm.filteredBooks;

        if (books.isEmpty) {
          return _buildEmptyState(isDark, '등록된 책이 없습니다');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookListCard(
              book: book,
              onTap: () => _navigateToBookDetail(book),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewBooksTab(bool isDark) {
    return Consumer<MyLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = vm.booksWithReview;

        if (books.isEmpty) {
          return _buildEmptyState(isDark, '독후감이 있는 책이 없습니다');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookListCard(
              book: book,
              onTap: () => _navigateToBookDetail(book),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.book,
            size: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
