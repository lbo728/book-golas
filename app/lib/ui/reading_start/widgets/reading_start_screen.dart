import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/core/widgets/book_image_widget.dart';
import 'package:book_golas/ui/reading_start/view_model/reading_start_view_model.dart';
import 'package:book_golas/ui/reading_start/widgets/schedule_change_modal.dart';
import 'package:book_golas/ui/reading_start/widgets/schedule_preview_widget.dart';
import 'package:book_golas/ui/reading_start/widgets/status_selector_widget.dart';
import 'package:book_golas/ui/book_detail/widgets/dialogs/update_target_date_dialog.dart';

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
  final FocusNode _searchFocusNode = FocusNode();

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
    } else {
      // 검색 필드에 자동 포커스
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
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
    _searchFocusNode.dispose();
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
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 커스텀 헤더
                _buildHeader(vm, isDark),
                // 콘텐츠
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBookTitleInputPage(vm, isDark),
                      _buildReadingSchedulePage(vm, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ReadingStartViewModel vm, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              if (vm.currentPageIndex > 0) {
                _previousPage(vm);
              } else {
                Navigator.pop(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                CupertinoIcons.back,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 제목
          Text(
            '독서 시작하기',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // 부제목 (검색 페이지일 때만)
          if (vm.currentPageIndex == 0)
            Text(
              '독서를 시작할 책을 검색해보세요.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookTitleInputPage(ReadingStartViewModel vm, bool isDark) {
    return Column(
      children: [
        // 검색 결과 리스트 영역
        Expanded(
          child: _buildSearchResultsList(vm, isDark),
        ),
        // 하단 바 (검색바 또는 독서시작하기 버튼)
        _buildBottomBar(vm, isDark),
      ],
    );
  }

  Widget _buildSearchResultsList(ReadingStartViewModel vm, bool isDark) {
    // 검색 중
    if (vm.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // 검색 결과 있음
    if (vm.searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: vm.searchResults.length,
        itemBuilder: (context, index) {
          final book = vm.searchResults[index];
          final isSelected =
              vm.selectedBook != null && vm.isSameBook(vm.selectedBook!, book);
          return _buildSearchResultItem(book, isSelected, vm, isDark);
        },
      );
    }

    // 검색어는 있지만 결과 없음
    if (_titleController.text.trim().isNotEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    // 초기 상태 (검색어 없음)
    return const SizedBox.shrink();
  }

  Widget _buildSearchResultItem(
    BookSearchResult book,
    bool isSelected,
    ReadingStartViewModel vm,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        vm.selectBook(book);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B7FFF).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF5B7FFF), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // 책 표지
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: book.imageUrl != null
                  ? Image.network(
                      book.imageUrl!,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.book,
                            size: 24,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 50,
                      height: 70,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(
                        Icons.book,
                        size: 24,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 페이지 수 + 선택 아이콘
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (book.totalPages != null)
                  Text(
                    '${book.totalPages}p',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF5B7FFF),
                    size: 22,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 하단 바: 책 선택 여부에 따라 검색바 또는 독서시작하기 버튼으로 전환
  Widget _buildBottomBar(ReadingStartViewModel vm, bool isDark) {
    // 책이 선택된 경우: 독서시작하기 버튼 + 뒤로가기 버튼
    if (vm.selectedBook != null) {
      return _buildSelectionModeBar(vm, isDark);
    }
    // 책이 선택되지 않은 경우: 검색바
    return _buildSearchModeBar(vm, isDark);
  }

  /// 검색 모드 바: 검색 입력 + 분리된 원형 X 버튼 (화면 닫기)
  Widget _buildSearchModeBar(ReadingStartViewModel vm, bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final foregroundColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.5);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // 검색바 (확장)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 검색 아이콘
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(
                            CupertinoIcons.search,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        // 검색 입력 필드
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 16,
                            ),
                            cursorColor: foregroundColor,
                            decoration: InputDecoration(
                              hintText: '책 제목을 입력해주세요.',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 16,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 분리된 원형 X 버튼
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 선택 모드 바: 뒤로가기 버튼 + 선택 완료 버튼
  Widget _buildSelectionModeBar(ReadingStartViewModel vm, bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final foregroundColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // 뒤로가기 버튼 (선택 해제)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                vm.clearSelection();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.back,
                      color: foregroundColor.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 선택 완료 버튼
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _nextPage(vm);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B7FFF).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '선택 완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 다이얼 UI 날짜 선택 모달 표시
  void _showDatePickerModal({
    required BuildContext context,
    required bool isDark,
    required DateTime selectedDate,
    required DateTime minimumDate,
    required void Function(DateTime) onDateChanged,
  }) {
    DateTime pickedDate = selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 드래그 핸들
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 선택된 날짜 표시
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${pickedDate.year}년 ${pickedDate.month}월 ${pickedDate.day}일',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 다이얼 피커
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: KoreanDatePicker(
                      isDark: isDark,
                      selectedDate: pickedDate,
                      minimumDate: minimumDate,
                      onDateChanged: (newDate) {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          pickedDate = newDate;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        onDateChanged(pickedDate);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReadingSchedulePage(ReadingStartViewModel vm, bool isDark) {
    final totalPages = vm.selectedBook?.totalPages ?? widget.totalPages ?? 0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // 우측으로 스와이프 시 뒤로가기
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          _previousPage(vm);
        }
      },
      child: SingleChildScrollView(
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
                onTap: () => _showDatePickerModal(
                  context: context,
                  isDark: isDark,
                  selectedDate: vm.plannedStartDate,
                  minimumDate: DateTime.now(),
                  onDateChanged: vm.setPlannedStartDate,
                ),
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
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '오늘부터 시작합니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF10B981),
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
              onTap: () => _showDatePickerModal(
                context: context,
                isDark: isDark,
                selectedDate: vm.targetDate,
                minimumDate: vm.effectiveStartDate,
                onDateChanged: vm.setTargetDate,
              ),
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
    ),
    );
  }
}
