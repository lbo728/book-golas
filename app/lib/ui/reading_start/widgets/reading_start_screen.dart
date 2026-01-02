import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/ui/core/widgets/book_image_widget.dart';
import 'package:book_golas/ui/reading_start/view_model/reading_start_view_model.dart';

class ReadingStartScreen extends StatelessWidget {
  final String? title;
  final int? totalPages;
  final String? imageUrl;

  const ReadingStartScreen({
    super.key,
    this.title,
    this.totalPages,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReadingStartViewModel(context.read<BookService>()),
      child: _ReadingStartContent(
        title: title,
        totalPages: totalPages,
        imageUrl: imageUrl,
      ),
    );
  }
}

class _ReadingStartContent extends StatefulWidget {
  final String? title;
  final int? totalPages;
  final String? imageUrl;

  const _ReadingStartContent({
    this.title,
    this.totalPages,
    this.imageUrl,
  });

  @override
  State<_ReadingStartContent> createState() => _ReadingStartContentState();
}

class _ReadingStartContentState extends State<_ReadingStartContent> {
  final TextEditingController _titleController = TextEditingController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<ReadingStartViewModel>();

    if (widget.title != null) {
      _titleController.text = widget.title!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        vm.goToSchedulePage();
      });
    }

    _titleController.addListener(() {
      vm.onSearchQueryChanged(_titleController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(ReadingStartViewModel vm) {
    if (vm.currentPageIndex < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      vm.goToSchedulePage();
    }
  }

  void _previousPage(ReadingStartViewModel vm) {
    if (vm.currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      vm.goToSearchPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ReadingStartViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                if (vm.currentPageIndex > 0) {
                  _previousPage(vm);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              '독서 시작하기',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBookTitleInputPage(vm, isDark),
              _buildReadingSchedulePage(vm, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookTitleInputPage(ReadingStartViewModel vm, bool isDark) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '책 이름을 입력해주세요.',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (vm.isSearching)
                const Center(child: CircularProgressIndicator())
              else if (vm.searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.searchResults.length,
                    itemBuilder: (context, index) {
                      final book = vm.searchResults[index];
                      final isSelected = vm.selectedBook != null &&
                          vm.isSameBook(vm.selectedBook!, book);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: ListTile(
                          selected: isSelected,
                          tileColor:
                              isSelected ? Colors.blue.withValues(alpha: 0.12) : null,
                          leading: book.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    book.imageUrl!,
                                    width: 40,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 40,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.book, size: 20),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.book, size: 20),
                                ),
                          title: Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (book.totalPages != null)
                                Text(
                                  '${book.totalPages}p',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          onTap: () => vm.selectBook(book),
                        ),
                      );
                    },
                  ),
                )
              else if (_titleController.text.trim().isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '검색 결과가 없습니다',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.canProceedToSchedule ? () => _nextPage(vm) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingSchedulePage(ReadingStartViewModel vm, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 150,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookImageWidget(
                    imageUrl: vm.selectedBook?.imageUrl ?? widget.imageUrl,
                    iconSize: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                vm.selectedBook?.title ?? _titleController.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (vm.selectedBook?.totalPages != null ||
                widget.totalPages != null) ...[
              Center(
                child: Text(
                  '${vm.selectedBook?.totalPages ?? widget.totalPages} 페이지',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              '독서 시작일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: vm.startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != vm.startDate) {
                  vm.setStartDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vm.startDate.year}년 ${vm.startDate.month}월 ${vm.startDate.day}일',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '목표 마감일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: vm.targetDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != vm.targetDate) {
                  vm.setTargetDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vm.targetDate.year}년 ${vm.targetDate.month}월 ${vm.targetDate.day}일',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                        final success = await vm.startReading(
                          fallbackTitle: _titleController.text,
                          fallbackImageUrl: widget.imageUrl,
                          fallbackTotalPages: widget.totalPages,
                        );

                        if (mounted) {
                          if (success) {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  vm.errorMessage ?? '독서 정보 저장에 실패했습니다.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: vm.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '독서 시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
