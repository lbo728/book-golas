import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/my_library/view_model/my_library_view_model.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyLibraryViewModel>().loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.scaffoldDark
          : AppColors.scaffoldLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            _buildFilterSection(isDark),
            Expanded(child: _buildBookList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        '나의 서재',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Consumer<MyLibraryViewModel>(
      builder: (context, vm, _) {
        final completedCount = vm.completedBooks.length;
        final reviewCount = vm.booksWithReview.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildTabButton(
                '전체 ($completedCount)',
                vm.selectedTabIndex == 0,
                isDark,
                () => vm.setSelectedTabIndex(0),
              ),
              const SizedBox(width: 12),
              _buildTabButton(
                '독후감 ($reviewCount)',
                vm.selectedTabIndex == 1,
                isDark,
                () => vm.setSelectedTabIndex(1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5)),
          ),
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

  Widget _buildBookList(bool isDark) {
    return Consumer<MyLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = vm.selectedTabIndex == 0
            ? vm.filteredBooks
            : vm.booksWithReview;

        if (books.isEmpty) {
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
                  vm.selectedTabIndex == 0 ? '완독한 책이 없습니다' : '독후감이 있는 책이 없습니다',
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

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _buildBookCard(book, isDark);
          },
        );
      },
    );
  }

  Widget _buildBookCard(Book book, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPlaceholderCover(isDark),
                  )
                : _buildPlaceholderCover(isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.author!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (book.rating != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < book.rating!
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        size: 14,
                        color: i < book.rating!
                            ? Colors.amber
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3)),
                      ),
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

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        CupertinoIcons.book,
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3),
      ),
    );
  }
}
