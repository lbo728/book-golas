import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';
import 'package:book_golas/ui/book_detail/view_model/book_detail_view_model.dart';
import 'package:book_golas/ui/book_detail/view_model/memorable_page_view_model.dart';
import 'package:book_golas/ui/book_detail/view_model/reading_progress_view_model.dart';
import 'package:book_golas/ui/book_detail/utils/ocr_utils.dart';
import 'widgets/dialogs/daily_target_dialog.dart';
import 'widgets/dialogs/update_page_dialog.dart';
import 'widgets/dialogs/update_target_date_dialog.dart';
import 'widgets/draggable_dismiss_image.dart';
import 'utils/sticky_tab_bar_delegate.dart';
import 'widgets/modals/add_memorable_page_modal.dart';
import 'widgets/modals/existing_image_modal.dart';
import 'widgets/tabs/memorable_pages_tab.dart';
import 'widgets/tabs/progress_history_tab.dart';
import 'widgets/tabs/detail_tab.dart';
import 'widgets/dashboard_progress_widget.dart';
import 'widgets/compact_book_header.dart';
import 'widgets/compact_reading_schedule.dart';
import 'widgets/compact_streak_row.dart';
import 'widgets/floating_action_bar.dart';
import 'widgets/custom_tab_bar.dart';
import 'widgets/sheets/delete_confirmation_sheet.dart';
import 'widgets/sheets/image_source_sheet.dart';
import 'widgets/sheets/full_title_sheet.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final bool showCelebration;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.showCelebration = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BookDetailViewModel(
            bookService: BookService(),
            initialBook: book,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MemorablePageViewModel(bookId: book.id!),
        ),
        ChangeNotifierProvider(
          create: (_) => ReadingProgressViewModel(bookId: book.id!),
        ),
      ],
      child: _BookDetailContent(showCelebration: showCelebration),
    );
  }
}

class _BookDetailContent extends StatefulWidget {
  final bool showCelebration;

  const _BookDetailContent({this.showCelebration = false});

  @override
  State<_BookDetailContent> createState() => _BookDetailContentState();
}

class _BookDetailContentState extends State<_BookDetailContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  double _animatedProgress = 0.0;
  final ScrollController _scrollController = ScrollController();

  // Confetti 컨트롤러
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bookVm = context.read<BookDetailViewModel>();
      final memorableVm = context.read<MemorablePageViewModel>();
      final progressVm = context.read<ReadingProgressViewModel>();

      // 최신 책 데이터 가져오기 (DB에서 fresh data)
      await bookVm.refreshBook();
      await bookVm.loadDailyAchievements();

      if (mounted) {
        _animatedProgress = bookVm.currentBook.currentPage / bookVm.currentBook.totalPages;
      }

      memorableVm.fetchBookImages();
      progressVm.fetchProgressHistory();

      // 축하 애니메이션 표시
      if (widget.showCelebration) {
        _showCelebration();
      }
    });
  }

  /// 축하 애니메이션 표시 (컨페티 + 스낵바)
  void _showCelebration() {
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController!.play();

    // 화이팅 메시지 스낵바
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '새로운 독서 여정을 시작합니다! 화이팅! 📚',
          type: SnackbarType.success,
        );
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimController.dispose();
    _scrollController.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Consumer<BookDetailViewModel>(
      builder: (context, bookVm, _) {
        final book = bookVm.currentBook;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '독서 상세',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CompactBookHeader(
                                imageUrl: book.imageUrl,
                                bookId: book.id!,
                                title: book.title,
                                author: book.author,
                                currentPage: book.currentPage,
                                totalPages: book.totalPages,
                                onImageTap: _showFullScreenImage,
                                onTitleTap: () => showFullTitleSheet(context: context, title: book.title),
                              ),
                              const SizedBox(height: 10),
                              CompactReadingSchedule(
                                startDate: book.startDate,
                                targetDate: book.targetDate,
                                attemptCount: bookVm.attemptCount,
                                onEditTap: () => _showUpdateTargetDateDialog(bookVm),
                              ),
                              const SizedBox(height: 12),
                              DashboardProgressWidget(
                                animatedProgress: _animatedProgress,
                                currentPage: book.currentPage,
                                totalPages: book.totalPages,
                                daysLeft: bookVm.daysLeft,
                                pagesLeft: bookVm.pagesLeft,
                                dailyTargetPages: book.dailyTargetPages,
                                onDailyTargetTap: () => _showDailyTargetChangeDialog(bookVm),
                              ),
                              const SizedBox(height: 12),
                              CompactStreakRow(dailyAchievements: bookVm.dailyAchievements),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: StickyTabBarDelegate(
                          child: CustomTabBar(tabController: _tabController),
                          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
                        ),
                      ),
                    ];
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Consumer<MemorablePageViewModel>(
                      builder: (context, memorableVm, _) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            MemorablePagesTab(
                              imagesFuture: Future.value(memorableVm.cachedImages ?? []),
                              cachedImages: memorableVm.cachedImages,
                              sortMode: memorableVm.sortMode,
                              isSelectionMode: memorableVm.isSelectionMode,
                              selectedImageIds: memorableVm.selectedImageIds,
                              onSortModeChanged: memorableVm.setSortMode,
                              onSelectionModeChanged: (mode) {
                                if (mode) {
                                  memorableVm.toggleSelectionMode();
                                } else {
                                  memorableVm.exitSelectionMode();
                                }
                              },
                              onImageSelected: (id, selected) => memorableVm.toggleImageSelection(id),
                              onDeleteSelected: () => _deleteSelectedImages(memorableVm),
                              onImageTap: (id, url, text, page) => _showExistingImageModal(id, url, text, pageNumber: page),
                              onImagesLoaded: memorableVm.onImagesLoaded,
                            ),
                            Consumer<ReadingProgressViewModel>(
                              builder: (context, progressVm, _) {
                                return ProgressHistoryTab(
                                  progressFuture: Future.value(progressVm.progressHistory ?? []),
                                  attemptCount: bookVm.attemptCount,
                                  attemptEncouragement: bookVm.attemptEncouragement,
                                  progressPercentage: bookVm.progressPercentage,
                                  daysLeft: bookVm.daysLeft,
                                  startDate: book.startDate,
                                  targetDate: book.targetDate,
                                );
                              },
                            ),
                            DetailTab(
                              book: book,
                              attemptCount: bookVm.attemptCount,
                              attemptEncouragement: bookVm.attemptEncouragement,
                              dailyAchievements: bookVm.dailyAchievements,
                              onTargetDateChange: () => _showUpdateTargetDateDialog(bookVm),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (isKeyboardOpen)
                const KeyboardDoneButton()
              else
                FloatingActionBar(
                  onUpdatePageTap: () => _showUpdatePageDialog(bookVm),
                  onAddMemorablePageTap: _showAddMemorablePageModal,
                ),
              // 컨페티 애니메이션
              if (_confettiController != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController!,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFF5B7FFF),
                      Color(0xFF10B981),
                      Color(0xFFFFD700),
                      Color(0xFFFF6B6B),
                      Color(0xFFAB47BC),
                    ],
                    numberOfParticles: 30,
                    gravity: 0.2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _animateProgress(double fromProgress, double toProgress) {
    _progressAnimController.reset();
    final progressTween = Tween<double>(begin: fromProgress, end: toProgress).animate(_progressAnimation);

    void listener() {
      setState(() => _animatedProgress = progressTween.value);
    }

    _progressAnimation.addListener(listener);
    _progressAnimController.forward().then((_) {
      _progressAnimation.removeListener(listener);
      setState(() => _animatedProgress = toProgress);
    });
  }

  Future<void> _showUpdatePageDialog(BookDetailViewModel bookVm) async {
    final book = bookVm.currentBook;
    await UpdatePageDialog.show(
      context: context,
      currentPage: book.currentPage,
      totalPages: book.totalPages,
      onUpdate: (newPage) => _updateCurrentPage(bookVm, newPage),
    );
  }

  Future<void> _updateCurrentPage(BookDetailViewModel bookVm, int newPage) async {
    final oldPage = bookVm.currentBook.currentPage;
    final totalPages = bookVm.currentBook.totalPages;
    final oldProgress = oldPage / totalPages;
    final newProgress = newPage / totalPages;
    final wasGoalAchieved = bookVm.isTodayGoalAchieved;

    final success = await bookVm.updateCurrentPage(newPage);
    if (success && mounted) {
      _animateProgress(oldProgress, newProgress);
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);

      final pagesRead = newPage - oldPage;
      if (bookVm.isTodayGoalAchieved) {
        CustomSnackbar.show(context, message: '오늘 목표 달성! +$pagesRead 페이지 🎉', type: SnackbarType.success);

        // 이번 업데이트로 목표 달성했으면 컨페티 표시
        if (!wasGoalAchieved) {
          _showGoalAchievedCelebration();
        }
      } else {
        final dailyTarget = bookVm.currentBook.dailyTargetPages ?? 0;
        final remaining = dailyTarget - bookVm.todayPagesRead;
        if (remaining > 0) {
          CustomSnackbar.show(context, message: '+$pagesRead 페이지! 오늘 목표까지 ${remaining}p 남음', type: SnackbarType.info);
        } else {
          CustomSnackbar.show(context, message: '+$pagesRead 페이지! ${newPage}p 도달', type: SnackbarType.success);
        }
      }

      context.read<ReadingProgressViewModel>().fetchProgressHistory();
    } else if (mounted) {
      CustomSnackbar.show(context, message: '오류가 발생했습니다', type: SnackbarType.error);
    }
  }

  /// 목표 달성 축하 애니메이션
  void _showGoalAchievedCelebration() {
    _confettiController?.dispose();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController!.play();
    setState(() {});
  }

  void _showDailyTargetChangeDialog(BookDetailViewModel bookVm) async {
    await DailyTargetDialog.show(
      context: context,
      book: bookVm.currentBook,
      pagesLeft: bookVm.pagesLeft,
      daysLeft: bookVm.daysLeft,
      onSave: (newDailyTarget) => bookVm.updateBook(bookVm.currentBook.copyWith(dailyTargetPages: newDailyTarget)),
    );
  }

  void _showUpdateTargetDateDialog(BookDetailViewModel bookVm) async {
    await UpdateTargetDateDialog.show(
      context: context,
      currentTargetDate: bookVm.currentBook.targetDate,
      nextAttemptCount: bookVm.attemptCount + 1,
      onConfirm: (newDate, newAttempt) async {
        final success = await bookVm.updateTargetDate(newDate, newAttempt);
        if (success && mounted) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
          CustomSnackbar.show(context, message: '$newAttempt번째 도전 시작! D-${bookVm.daysLeft}', type: SnackbarType.info, icon: Icons.flag);
        }
      },
    );
  }

  void _showFullScreenImage(String imageId, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissNetworkImage(animation: animation, imageUrl: imageUrl, imageId: imageId);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showImageFullscreenOnly(Uint8List imageBytes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissImage(animation: animation, imageBytes: imageBytes);
        },
      ),
    );
  }

  void _showAddMemorablePageModal() async {
    final memorableVm = context.read<MemorablePageViewModel>();
    final bookVm = context.read<BookDetailViewModel>();

    final result = await showAddMemorablePageModal(
      context: context,
      initialImageBytes: memorableVm.pendingImageBytes,
      initialExtractedText: memorableVm.pendingExtractedText,
      initialPageNumber: memorableVm.pendingPageNumber,
      totalPages: bookVm.currentBook.totalPages,
      onImageTap: _showImageFullscreenOnly,
      onShowImageSourceSheet: (onImageSelected) => _showImageSourceActionSheet(onImageSelected: onImageSelected),
      onShowReplaceImageConfirmation: (onConfirm) async {
        final confirmed = await showReplaceImageConfirmationSheet(context: context);
        if (confirmed == true) onConfirm();
      },
      onExtractText: (imageBytes, onResult) {
        if (!mounted) return;
        extractTextFromLocalImage(context, imageBytes, onResult);
      },
      onUpload: ({Uint8List? imageBytes, required String extractedText, int? pageNumber}) async {
        return await _uploadAndSaveMemorablePage(imageBytes: imageBytes, extractedText: extractedText, pageNumber: pageNumber);
      },
      onStateChanged: (imageBytes, text, pageNumber) {
        if (imageBytes != null || text.isNotEmpty || pageNumber != null) {
          memorableVm.setPendingImage(
            bytes: imageBytes ?? Uint8List(0),
            extractedText: text,
            pageNumber: pageNumber,
          );
        }
      },
    );

    if (!mounted) return;

    if (result != null && result['clear'] == true) {
      memorableVm.clearPendingImage();
    }
  }

  Future<bool> _uploadAndSaveMemorablePage({Uint8List? imageBytes, required String extractedText, int? pageNumber}) async {
    final memorableVm = context.read<MemorablePageViewModel>();
    final bookVm = context.read<BookDetailViewModel>();

    try {
      String? publicUrl;
      if (imageBytes != null) {
        final fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storage = Supabase.instance.client.storage;
        await storage.from('book-images').uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));
        publicUrl = storage.from('book-images').getPublicUrl(fileName);
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('book_images').insert({
        'book_id': bookVm.currentBook.id,
        'user_id': userId,
        'image_url': publicUrl,
        'caption': '',
        'extracted_text': extractedText.isEmpty ? null : extractedText,
        'page_number': pageNumber,
        'created_at': DateTime.now().toIso8601String(),
      });

      await memorableVm.fetchBookImages();
      memorableVm.clearPendingImage();

      if (mounted) {
        _tabController.animateTo(0);
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        CustomSnackbar.show(context, message: '기록이 저장되었습니다', type: SnackbarType.success);
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 업로드 실패: $e');
      debugPrint('🔴 스택 트레이스: $stackTrace');
      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError = errorMessage.contains('SocketException') || errorMessage.contains('Connection') || errorMessage.contains('timeout');
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('업로드 실패'),
            content: Text(isNetworkError ? '네트워크 연결을 확인해주세요.\n연결 상태가 양호하면 다시 시도해주세요.' : '기록을 저장하는 중 오류가 발생했습니다.\n업로드 버튼을 눌러 다시 시도해주세요.'),
            actions: [CupertinoDialogAction(child: const Text('확인'), onPressed: () => Navigator.pop(dialogContext))],
          ),
        );
      }
      return false;
    }
  }

  Future<void> _showImageSourceActionSheet({required Function(Uint8List imageBytes, String ocrText, int? pageNumber) onImageSelected}) async {
    final source = await showImageSourceSheet(context: context);
    if (source != null && mounted) {
      await pickImageAndExtractText(context, source, onImageSelected);
    }
  }

  Future<void> _deleteSelectedImages(MemorablePageViewModel memorableVm) async {
    if (memorableVm.selectedImageIds.isEmpty) return;

    final count = memorableVm.selectedImageIds.length;
    final confirmed = await showBatchDeleteConfirmationSheet(context: context, count: count);
    if (confirmed != true) return;

    final success = await memorableVm.deleteSelectedImages();
    if (success && mounted) {
      CustomSnackbar.show(context, message: '$count개 항목이 삭제되었습니다', type: SnackbarType.success);
    }
  }

  void _showExistingImageModal(String imageId, String? initialImageUrl, String? extractedText, {int? pageNumber}) {
    final memorableVm = context.read<MemorablePageViewModel>();
    final bookVm = context.read<BookDetailViewModel>();

    showExistingImageModal(
      context: context,
      imageId: imageId,
      initialImageUrl: initialImageUrl,
      initialExtractedText: extractedText,
      pageNumber: pageNumber,
      totalPages: bookVm.currentBook.totalPages,
      cachedEditedText: memorableVm.editedTexts[imageId],
      onFullScreenImage: (id, url) {
        if (url != null) _showFullScreenImage(id, url);
      },
      onDeleteImage: (id, url, {bool dismissParentOnDelete = false}) async {
        final confirmed = await showDeleteConfirmationSheet(context: context, title: '삭제하시겠습니까?', message: '이 항목을 삭제하면 복구할 수 없습니다.');
        if (confirmed != true) return;
        if (dismissParentOnDelete && mounted) Navigator.pop(context);
        await memorableVm.deleteBookImage(id);
      },
      onReExtractText: ({required String imageUrl, required void Function(String extractedText) onConfirm}) {
        if (!mounted) return;
        reExtractTextFromImage(context, imageUrl: imageUrl, onConfirm: onConfirm);
      },
      onReplaceImage: ({required String imageId, required String currentText, required void Function(String? newImageUrl) onReplaced}) async {
        final source = await showImageReplaceOptionsSheet(context: context);
        if (source != null && mounted) {
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(source: source);
          if (pickedFile == null) return;
          final imageBytes = await pickedFile.readAsBytes();
          if (!mounted) return;
          final newUrl = await memorableVm.replaceImage(imageId: imageId, imageBytes: imageBytes, extractedText: currentText, pageNumber: null);
          if (newUrl != null && mounted) {
            CustomSnackbar.show(context, message: '이미지가 교체되었습니다', type: SnackbarType.success);
          }
          onReplaced(newUrl);
        }
      },
      onSave: ({required String imageId, required String extractedText, required int? pageNumber}) async {
        final success = await memorableVm.updateImageRecord(imageId: imageId, extractedText: extractedText, pageNumber: pageNumber);
        return success;
      },
      onTextEdited: (id, text) => memorableVm.setEditedText(id, text),
    );
  }
}
