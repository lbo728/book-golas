import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/domain/models/home_display_mode.dart';
import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';
import 'package:book_golas/ui/home/view_model/home_view_model.dart';
import 'package:book_golas/ui/home/widgets/home_mode_toggle_button.dart';
import 'package:book_golas/ui/home/widgets/ai_feature_banner.dart';
import 'package:book_golas/ui/book_list/view_model/book_list_view_model.dart';
import 'package:book_golas/ui/book_list/widgets/book_list_screen.dart';
import 'package:book_golas/ui/book_list/widgets/sheets/reading_books_selection_sheet.dart';
import 'package:book_golas/ui/reading_progress/widgets/reading_progress_screen.dart';
import 'package:book_golas/ui/reading_start/widgets/reading_start_screen.dart';
import 'package:book_golas/ui/recall/widgets/recall_search_sheet.dart';

class HomeScreen extends StatefulWidget {
  final void Function(VoidCallback updatePage, VoidCallback addMemorable)?
      onCallbacksReady;

  const HomeScreen({
    super.key,
    this.onCallbacksReady,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<HomeModeToggleButtonState> _toggleButtonKey = GlobalKey();

  void _navigateToRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReadingStartScreen(),
      ),
    );
  }

  void _showRecallBookSelection() {
    final bookListVm = context.read<BookListViewModel>();
    final readingBooks = bookListVm.readingBooks;

    if (readingBooks.isEmpty) {
      CustomSnackbar.show(
        context,
        message: '진행 중인 독서가 없습니다. 먼저 책을 등록해주세요.',
        type: SnackbarType.info,
        bottomOffset: 100,
      );
      return;
    }

    if (readingBooks.length == 1) {
      _openRecallSheet(readingBooks.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadingBooksSelectionSheet(
        books: readingBooks,
        onBookSelected: (book) {
          Navigator.pop(context);
          _openRecallSheet(book);
        },
      ),
    );
  }

  void _openRecallSheet(Book book) {
    showRecallSearchSheet(
      context: context,
      bookId: book.id!,
    );
  }

  void _toggleDisplayMode(HomeViewModel vm) {
    if (vm.displayMode == HomeDisplayMode.allBooks) {
      vm.setDisplayMode(HomeDisplayMode.readingDetail);
      _handleReadingDetailMode(vm);
    } else {
      vm.setDisplayMode(HomeDisplayMode.allBooks);
      _showModeChangeSnackBar('전체 독서 보기로 전환되었습니다.');
    }
  }

  void _handleReadingDetailMode(HomeViewModel vm) {
    final bookListVm = context.read<BookListViewModel>();
    final readingBooks = bookListVm.readingBooks;

    if (readingBooks.isEmpty) {
      CustomSnackbar.show(
        context,
        message: '진행 중인 독서가 없습니다',
        type: SnackbarType.info,
        bottomOffset: 100,
      );
      vm.setDisplayMode(HomeDisplayMode.allBooks);
      return;
    }

    if (readingBooks.length == 1) {
      vm.setSelectedBook(readingBooks.first.id!);
      _showModeChangeSnackBar('진행 중인 독서 보기로 전환되었습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadingBooksSelectionSheet(
        books: readingBooks,
        onBookSelected: (book) {
          Navigator.pop(context);
          vm.setSelectedBook(book.id!);
          _showModeChangeSnackBar('진행 중인 독서 보기로 전환되었습니다.');
        },
      ),
    );
  }

  void _showModeChangeSnackBar(String message) {
    _toggleButtonKey.currentState?.triggerTransitionAnimation();
    CustomSnackbar.show(
      context,
      message: message,
      type: SnackbarType.success,
      bottomOffset: 100,
    );
  }

  String _getToggleButtonLabel(HomeDisplayMode mode) {
    return mode == HomeDisplayMode.readingDetail ? '전체 독서 보기' : '진행 중인 독서만 보기';
  }

  Book? _findSelectedBook(String? bookId, List<Book> books) {
    if (bookId == null) return null;
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<HomeViewModel, BookListViewModel>(
      builder: (context, vm, bookListVm, _) {
        if (!vm.isPreferencesLoaded) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
            body: const SizedBox.shrink(),
          );
        }

        final selectedBook =
            _findSelectedBook(vm.selectedBookId, bookListVm.books);
        final isReadingDetailMode =
            vm.displayMode == HomeDisplayMode.readingDetail;
        final isReadingDetail = isReadingDetailMode && selectedBook != null;

        if (isReadingDetailMode &&
            selectedBook == null &&
            bookListVm.isLoading) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
            body: const SizedBox.shrink(),
          );
        }

        if (isReadingDetail) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildReadingDetailHeader(vm, isDark),
                Expanded(
                  child: ReadingProgressScreen(
                    book: selectedBook,
                    onCallbacksReady: widget.onCallbacksReady,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          appBar: _buildAppBar(vm, isDark),
          body: Column(
            children: [
              AiFeatureBanner(
                onRecallTap: _showRecallBookSelection,
                onRecommendTap: _navigateToRecommendation,
              ),
              const Expanded(
                child: BookListScreen(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingDetailHeader(HomeViewModel vm, bool isDark) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HomeModeToggleButton(
            key: _toggleButtonKey,
            label: _getToggleButtonLabel(vm.displayMode),
            icon: Icons.sync_alt,
            onTap: () => _toggleDisplayMode(vm),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomeViewModel vm, bool isDark) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: const Text('독서 목록'),
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
      actions: [
        HomeModeToggleButton(
          key: _toggleButtonKey,
          label: _getToggleButtonLabel(vm.displayMode),
          icon: Icons.sync_alt,
          onTap: () => _toggleDisplayMode(vm),
        ),
      ],
    );
  }
}
