import 'dart:async';

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

  static final GlobalKey<_MyLibraryScreenState> globalKey =
      GlobalKey<_MyLibraryScreenState>();

  static void cycleToNextTab() {
    globalKey.currentState?.cycleToNextTab();
  }

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _readingSearchController =
      TextEditingController();
  final TextEditingController _reviewSearchController = TextEditingController();
  Timer? _readingDebounceTimer;
  Timer? _reviewDebounceTimer;

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

  void cycleToNextTab() {
    final nextIndex = (_tabController.index + 1) % 2;
    _tabController.animateTo(nextIndex);
  }

  void _onReadingSearchChanged(String query) {
    _readingDebounceTimer?.cancel();
    _readingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<MyLibraryViewModel>().setReadingSearchQuery(query);
    });
  }

  void _onReviewSearchChanged(String query) {
    _reviewDebounceTimer?.cancel();
    _reviewDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<MyLibraryViewModel>().setReviewSearchQuery(query);
    });
  }

  @override
  void dispose() {
    _readingDebounceTimer?.cancel();
    _reviewDebounceTimer?.cancel();
    _readingSearchController.dispose();
    _reviewSearchController.dispose();
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
                tabs: ['독서 ($allCount)', '독후감 ($reviewCount)'],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingTab(isDark),
          _buildReviewTab(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required bool isDark,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '제목, 저자로 검색',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onClear();
                  },
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
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

  Widget _buildReadingTab(bool isDark) {
    return Column(
      children: [
        _buildSearchBar(
          isDark: isDark,
          controller: _readingSearchController,
          onChanged: _onReadingSearchChanged,
          onClear: () =>
              context.read<MyLibraryViewModel>().setReadingSearchQuery(''),
        ),
        _buildFilterSection(isDark),
        Expanded(
          child: Consumer<MyLibraryViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = vm.filteredBooks;

              if (books.isEmpty) {
                final emptyMessage = vm.readingSearchQuery.isNotEmpty
                    ? '검색 결과가 없습니다'
                    : '등록된 책이 없습니다';
                return _buildEmptyState(isDark, emptyMessage);
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
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTab(bool isDark) {
    return Column(
      children: [
        _buildSearchBar(
          isDark: isDark,
          controller: _reviewSearchController,
          onChanged: _onReviewSearchChanged,
          onClear: () =>
              context.read<MyLibraryViewModel>().setReviewSearchQuery(''),
        ),
        Expanded(
          child: Consumer<MyLibraryViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = vm.booksWithReview;

              if (books.isEmpty) {
                final emptyMessage = vm.reviewSearchQuery.isNotEmpty
                    ? '검색 결과가 없습니다'
                    : '독후감이 있는 책이 없습니다';
                return _buildEmptyState(isDark, emptyMessage);
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
          ),
        ),
      ],
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
