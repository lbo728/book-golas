import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/core/widgets/book_image_widget.dart';
import 'package:book_golas/ui/reading_start/view_model/reading_start_view_model.dart';
import 'package:book_golas/ui/reading_start/widgets/schedule_change_modal.dart';
import 'package:book_golas/ui/reading_start/widgets/schedule_preview_widget.dart';
import 'package:book_golas/ui/reading_start/widgets/status_selector_widget.dart';

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
    final totalPages = vm.selectedBook?.totalPages ?? widget.totalPages ?? 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 정보
            Center(
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookImageWidget(
                    imageUrl: vm.selectedBook?.imageUrl ?? widget.imageUrl,
                    iconSize: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                vm.selectedBook?.title ?? _titleController.text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (totalPages > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '$totalPages 페이지',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 독서 상태 선택
            StatusSelectorWidget(
              selectedStatus: vm.readingStatus,
              onStatusChanged: vm.setReadingStatus,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 시작일 선택 (읽을 예정일 때만 표시)
            if (vm.readingStatus == BookStatus.planned) ...[
              Text(
                '독서 시작 예정일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: vm.plannedStartDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    vm.setPlannedStartDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${vm.plannedStartDate.year}년 ${vm.plannedStartDate.month}월 ${vm.plannedStartDate.day}일',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // 바로 시작 선택 시 오늘 시작 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '오늘부터 시작합니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 목표 마감일
            Text(
              '목표 마감일',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: vm.targetDate,
                  firstDate: vm.effectiveStartDate,
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != vm.targetDate) {
                  vm.setTargetDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vm.targetDate.year}년 ${vm.targetDate.month}월 ${vm.targetDate.day}일',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 스케줄 미리보기
            if (totalPages > 0)
              SchedulePreviewWidget(
                totalPages: totalPages,
                startDate: vm.effectiveStartDate,
                targetDate: vm.targetDate,
                dailyTargetPages: vm.dailyTargetPages,
                isDark: isDark,
                onChangeSchedule: () async {
                  final newTarget = await ScheduleChangeModal.show(
                    context: context,
                    totalPages: totalPages,
                    startDate: vm.effectiveStartDate,
                    targetDate: vm.targetDate,
                    currentDailyTarget: vm.dailyTargetPages,
                  );
                  if (newTarget != null) {
                    vm.setDailyTargetPages(newTarget);
                  }
                },
              ),

            const SizedBox(height: 24),

            // 독서 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                        final success = await vm.startReading(
                          fallbackTitle: _titleController.text,
                          fallbackImageUrl: widget.imageUrl,
                          fallbackTotalPages: widget.totalPages,
                        );

                        if (mounted && success && vm.createdBook != null) {
                          // BookDetailScreen으로 이동 (축하 애니메이션 포함)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(
                                book: vm.createdBook!,
                                showCelebration: true,
                              ),
                            ),
                          );
                        } else if (mounted && !success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                vm.errorMessage ?? '독서 정보 저장에 실패했습니다.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7FFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
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
                    : Text(
                        vm.readingStatus == BookStatus.planned
                            ? '독서 예약하기'
                            : '독서 시작',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
