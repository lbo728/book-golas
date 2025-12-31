import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/core/widgets/custom_snackbar.dart';
import 'package:book_golas/features/book_detail/view_model/book_detail_view_model.dart';
import 'package:book_golas/features/book_detail/view_model/memorable_page_view_model.dart';
import 'package:book_golas/features/book_detail/view_model/reading_progress_view_model.dart';
import 'package:book_golas/features/book_detail/utils/ocr_utils.dart';
import 'dialogs/daily_target_dialog.dart';
import 'dialogs/update_page_dialog.dart';
import 'dialogs/update_target_date_dialog.dart';
import 'draggable_dismiss_image.dart';
import 'sticky_tab_bar_delegate.dart';
import 'modals/add_memorable_page_modal.dart';
import 'modals/existing_image_modal.dart';
import 'tabs/memorable_pages_tab.dart';
import 'tabs/progress_history_tab.dart';
import 'tabs/detail_tab.dart';
import 'components/dashboard_progress_widget.dart';
import 'components/compact_book_header.dart';
import 'components/compact_reading_schedule.dart';
import 'components/compact_streak_row.dart';
import 'components/floating_action_bar.dart';
import 'components/custom_tab_bar.dart';
import 'sheets/delete_confirmation_sheet.dart';
import 'sheets/image_source_sheet.dart';
import 'sheets/full_title_sheet.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
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
      child: _BookDetailContent(book: book),
    );
  }
}

class _BookDetailContent extends StatefulWidget {
  final Book book;

  const _BookDetailContent({required this.book});

  @override
  State<_BookDetailContent> createState() => _BookDetailContentState();
}

class _BookDetailContentState extends State<_BookDetailContent>
    with TickerProviderStateMixin {
  final BookService _bookService = BookService();
  late Book _currentBook;
  late TabController _tabController;
  late int _attemptCount;
  Map<String, bool> _dailyAchievements = {};

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  double _animatedProgress = 0.0;

  final ScrollController _scrollController = ScrollController();

  late Future<List<Map<String, dynamic>>> _bookImagesFuture;
  late Future<List<Map<String, dynamic>>> _progressHistoryFuture;

  List<Map<String, dynamic>>? _cachedImages;

  final Map<String, String> _editedTexts = {};

  bool _isSelectionMode = false;
  final Set<String> _selectedImageIds = {};

  String _memorableSortMode = 'page_desc';

  Uint8List? _pendingImageBytes;
  String _pendingExtractedText = '';
  int? _pendingPageNumber;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _attemptCount = widget.book.attemptCount;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadDailyAchievements();

    _animatedProgress = _currentBook.currentPage / _currentBook.totalPages;
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.elasticOut,
    );

    _bookImagesFuture = fetchBookImages(_currentBook.id!);
    _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAchievements() async {
    final achievements = <String, bool>{};
    final startDate = _currentBook.startDate;
    final now = DateTime.now();

    for (var i = 0; i < now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      achievements[dateKey] = i % 3 != 1;
    }

    setState(() {
      _dailyAchievements = achievements;
    });
  }

  int get _daysLeft {
    final now = DateTime.now();
    final target = _currentBook.targetDate;
    final days = target.difference(now).inDays;
    return days >= 0 ? days + 1 : days;
  }

  double get _progressPercentage {
    if (_currentBook.totalPages == 0) return 0;
    return (_currentBook.currentPage / _currentBook.totalPages * 100)
        .clamp(0, 100);
  }

  int get _pagesLeft => (_currentBook.totalPages - _currentBook.currentPage)
      .clamp(0, _currentBook.totalPages);

  String get _attemptEncouragement {
    switch (_attemptCount) {
      case 1:
        return '최고!';
      case 2:
        return '잘하고 있다';
      case 3:
        return '화이팅!';
      default:
        return '내가 더 도와줄게...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '독서 상세',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
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
                            imageUrl: _currentBook.imageUrl,
                            bookId: _currentBook.id!,
                            title: _currentBook.title,
                            author: _currentBook.author,
                            currentPage: _currentBook.currentPage,
                            totalPages: _currentBook.totalPages,
                            onImageTap: (heroTag, imageUrl) => _showFullScreenImage(heroTag, imageUrl),
                            onTitleTap: () => showFullTitleSheet(context: context, title: _currentBook.title),
                          ),
                          const SizedBox(height: 10),
                          CompactReadingSchedule(
                            startDate: _currentBook.startDate,
                            targetDate: _currentBook.targetDate,
                            attemptCount: _attemptCount,
                            onEditTap: _showUpdateTargetDateDialogWithConfirm,
                          ),
                          const SizedBox(height: 12),
                          DashboardProgressWidget(
                            animatedProgress: _animatedProgress,
                            currentPage: _currentBook.currentPage,
                            totalPages: _currentBook.totalPages,
                            daysLeft: _daysLeft,
                            pagesLeft: _pagesLeft,
                            dailyTargetPages: _currentBook.dailyTargetPages,
                            onDailyTargetTap: _showDailyTargetChangeDialog,
                          ),
                          const SizedBox(height: 12),
                          CompactStreakRow(dailyAchievements: _dailyAchievements),
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MemorablePagesTab(
                      imagesFuture: _bookImagesFuture,
                      cachedImages: _cachedImages,
                      sortMode: _memorableSortMode,
                      isSelectionMode: _isSelectionMode,
                      selectedImageIds: _selectedImageIds,
                      onSortModeChanged: (mode) => setState(() => _memorableSortMode = mode),
                      onSelectionModeChanged: (mode) => setState(() => _isSelectionMode = mode),
                      onImageSelected: (id, selected) => setState(() {
                        if (selected) {
                          _selectedImageIds.add(id);
                        } else {
                          _selectedImageIds.remove(id);
                        }
                      }),
                      onDeleteSelected: _deleteSelectedImages,
                      onImageTap: (id, url, text, page) => _showExistingImageModal(id, url, text, pageNumber: page),
                      onImagesLoaded: (images) => _cachedImages = images,
                    ),
                    ProgressHistoryTab(
                      progressFuture: _progressHistoryFuture,
                      attemptCount: _attemptCount,
                      attemptEncouragement: _attemptEncouragement,
                      progressPercentage: _progressPercentage,
                      daysLeft: _daysLeft,
                      startDate: _currentBook.startDate,
                      targetDate: _currentBook.targetDate,
                    ),
                    DetailTab(
                      book: _currentBook,
                      attemptCount: _attemptCount,
                      attemptEncouragement: _attemptEncouragement,
                      dailyAchievements: _dailyAchievements,
                      onTargetDateChange: _showUpdateTargetDateDialogWithConfirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isKeyboardOpen)
            const KeyboardDoneButton()
          else
            FloatingActionBar(
              onUpdatePageTap: _showUpdatePageDialog,
              onAddMemorablePageTap: _showAddMemorablePageModal,
            ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePageDialog() async {
    await UpdatePageDialog.show(
      context: context,
      currentPage: _currentBook.currentPage,
      totalPages: _currentBook.totalPages,
      onUpdate: _updateCurrentPage,
    );
  }

  Future<void> _updateCurrentPage(int newPage) async {
    final oldPage = _currentBook.currentPage;
    final oldProgress = oldPage / _currentBook.totalPages;
    final newProgress = newPage / _currentBook.totalPages;

    try {
      final updatedBook =
          await _bookService.updateCurrentPage(_currentBook.id!, newPage);
      if (updatedBook != null) {
        _animateProgress(oldPage, newPage, oldProgress, newProgress);

        setState(() {
          _currentBook = updatedBook;
          _progressHistoryFuture = fetchProgressHistory(_currentBook.id!);
        });

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );

        if (mounted) {
          final pagesRead = newPage - oldPage;
          CustomSnackbar.show(
            context,
            message: '+$pagesRead 페이지! ${newPage}p 도달',
            type: SnackbarType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '오류가 발생했습니다',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _animateProgress(int fromPage, int toPage, double fromProgress, double toProgress) {
    _progressAnimController.reset();

    final progressTween = Tween<double>(begin: fromProgress, end: toProgress).animate(_progressAnimation);

    void listener() {
      setState(() {
        _animatedProgress = progressTween.value;
      });
    }

    _progressAnimation.addListener(listener);
    _progressAnimController.forward().then((_) {
      _progressAnimation.removeListener(listener);
      setState(() {
        _animatedProgress = toProgress;
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchBookImages(String bookId) async {
    final response = await Supabase.instance.client
        .from('book_images')
        .select('id, image_url, extracted_text, page_number, created_at')
        .eq('book_id', bookId);

    final images = (response as List)
        .map((e) => {
              'id': e['id'] as String,
              'image_url': e['image_url'] as String?,
              'extracted_text': e['extracted_text'] as String?,
              'page_number': e['page_number'] as int?,
              'created_at': e['created_at'] as String,
            })
        .toList();

    images.sort((a, b) {
      final pageA = a['page_number'] as int?;
      final pageB = b['page_number'] as int?;

      if (pageA != null && pageB == null) return -1;
      if (pageA == null && pageB != null) return 1;
      if (pageA != null && pageB != null) {
        final pageCompare = pageB.compareTo(pageA);
        if (pageCompare != 0) return pageCompare;
      }

      final dateA = a['created_at'] as String;
      final dateB = b['created_at'] as String;
      return dateB.compareTo(dateA);
    });

    return images;
  }

  Future<void> _deleteBookImage(String imageId, String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final storage = Supabase.instance.client.storage;
      final bucketPath =
          imageUrl.split('/storage/v1/object/public/book-images/').last;
      await storage.from('book-images').remove([bucketPath]);
    }
    await Supabase.instance.client
        .from('book_images')
        .delete()
        .eq('id', imageId);

    setState(() {
      if (_cachedImages != null) {
        _cachedImages = _cachedImages!.where((img) => img['id'] != imageId).toList();
      }
      _bookImagesFuture = fetchBookImages(_currentBook.id!);
    });
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;

    final count = _selectedImageIds.length;
    final confirmed = await showBatchDeleteConfirmationSheet(context: context, count: count);
    if (confirmed != true) return;

    final idsToDelete = _selectedImageIds.toList();
    for (final imageId in idsToDelete) {
      final image = _cachedImages?.firstWhere(
        (img) => img['id'] == imageId,
        orElse: () => {},
      );
      final imageUrl = image?['image_url'] as String?;
      await _deleteBookImage(imageId, imageUrl);
    }

    setState(() {
      _selectedImageIds.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      CustomSnackbar.show(context, message: '$count개 항목이 삭제되었습니다', type: SnackbarType.success);
    }
  }

  void _confirmDeleteImage(String imageId, String? imageUrl, {bool dismissParentOnDelete = false}) async {
    final confirmed = await showDeleteConfirmationSheet(
      context: context,
      title: '삭제하시겠습니까?',
      message: '이 항목을 삭제하면 복구할 수 없습니다.',
    );
    if (confirmed != true) return;

    if (dismissParentOnDelete && mounted) {
      Navigator.pop(context);
    }
    await _deleteBookImage(imageId, imageUrl);
  }

  Future<void> _showReplaceImageConfirmation({required VoidCallback onConfirm}) async {
    final confirmed = await showReplaceImageConfirmationSheet(context: context);
    if (confirmed == true) {
      onConfirm();
    }
  }

  void _showImageFullscreenOnly(Uint8List imageBytes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissImage(
            animation: animation,
            imageBytes: imageBytes,
          );
        },
      ),
    );
  }

  Future<bool> _uploadAndSaveMemorablePage({
    Uint8List? imageBytes,
    required String extractedText,
    int? pageNumber,
  }) async {
    try {
      String? publicUrl;

      if (imageBytes != null) {
        final fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storage = Supabase.instance.client.storage;
        await storage.from('book-images').uploadBinary(fileName, imageBytes,
            fileOptions: const FileOptions(upsert: true));
        publicUrl = storage.from('book-images').getPublicUrl(fileName);
      }

      final result = await Supabase.instance.client.from('book_images').insert({
        'book_id': _currentBook.id,
        'image_url': publicUrl,
        'caption': '',
        'extracted_text': extractedText.isEmpty ? null : extractedText,
        'page_number': pageNumber,
      }).select().single();

      setState(() {
        if (_cachedImages != null) {
          _cachedImages = [result, ..._cachedImages!];
        }
        _bookImagesFuture = fetchBookImages(_currentBook.id!);
      });

      if (mounted) {
        _tabController.animateTo(0);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        CustomSnackbar.show(
          context,
          message: '인상적인 페이지가 저장되었습니다',
          type: SnackbarType.success,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError = errorMessage.contains('SocketException') ||
            errorMessage.contains('Connection') ||
            errorMessage.contains('timeout');

        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('업로드 실패'),
            content: Text(
              isNetworkError
                  ? '네트워크 연결을 확인해주세요.\n연결 상태가 양호하면 다시 시도해주세요.'
                  : '인상적인 페이지를 저장하는 중 오류가 발생했습니다.\n업로드 버튼을 눌러 다시 시도해주세요.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
      return false;
    }
  }

  void _showAddMemorablePageModal() {
    showAddMemorablePageModal(
      context: context,
      initialImageBytes: _pendingImageBytes,
      initialExtractedText: _pendingExtractedText,
      initialPageNumber: _pendingPageNumber,
      totalPages: _currentBook.totalPages,
      onImageTap: _showImageFullscreenOnly,
      onShowImageSourceSheet: (onImageSelected) {
        _showImageSourceActionSheet(onImageSelected: onImageSelected);
      },
      onShowReplaceImageConfirmation: (onConfirm) {
        _showReplaceImageConfirmation(onConfirm: onConfirm);
      },
      onExtractText: (imageBytes, onResult) {
        if (!mounted) return;
        extractTextFromLocalImage(context, imageBytes, onResult);
      },
      onUpload: ({
        Uint8List? imageBytes,
        required String extractedText,
        int? pageNumber,
      }) async {
        return await _uploadAndSaveMemorablePage(
          imageBytes: imageBytes,
          extractedText: extractedText,
          pageNumber: pageNumber,
        );
      },
      onDismiss: (imageBytes, text, pageNumber) {
        _pendingImageBytes = imageBytes;
        _pendingExtractedText = text;
        _pendingPageNumber = pageNumber;
      },
    );
  }

  Future<void> _showImageSourceActionSheet({
    required Function(Uint8List imageBytes, String ocrText, int? pageNumber) onImageSelected,
  }) async {
    final source = await showImageSourceSheet(context: context);
    if (source != null && mounted) {
      await pickImageAndExtractText(context, source, onImageSelected);
    }
  }

  Future<void> _pickImageOnly(
    ImageSource source,
    Function(Uint8List imageBytes) onComplete,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    onComplete(imageBytes);
  }

  Future<List<Map<String, dynamic>>> fetchProgressHistory(String bookId) async {
    final response = await Supabase.instance.client
        .from('reading_progress_history')
        .select('page, created_at')
        .eq('book_id', bookId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => {
              'page': e['page'] as int,
              'created_at': DateTime.parse(e['created_at'] as String),
            })
        .toList();
  }

  Future<void> _showReplaceImageOptionsOverModal({
    required String imageId,
    required String currentText,
    required Function(String? newImageUrl) onReplaced,
  }) async {
    final source = await showImageReplaceOptionsSheet(context: context);
    if (source != null && mounted) {
      _pickImageOnly(source, (imageBytes) async {
        final newUrl = await _replaceImage(imageId, imageBytes, currentText, null);
        onReplaced(newUrl);
      });
    }
  }

  Future<String?> _replaceImage(String imageId, Uint8List imageBytes, String extractedText, int? pageNumber) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentBook.id}.jpg';
      final storagePath = 'book_images/$fileName';

      await Supabase.instance.client.storage
          .from('book-images')
          .uploadBinary(storagePath, imageBytes);

      final imageUrl = Supabase.instance.client.storage
          .from('book-images')
          .getPublicUrl(storagePath);

      await Supabase.instance.client.from('book_images').update({
        'image_url': imageUrl,
        'extracted_text': extractedText,
        'page_number': pageNumber,
      }).eq('id', imageId);

      _bookImagesFuture = fetchBookImages(_currentBook.id!);
      setState(() {});

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '이미지가 교체되었습니다',
          type: SnackbarType.success,
        );
      }
      return imageUrl;
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '이미지 교체 실패',
          type: SnackbarType.error,
        );
      }
      return null;
    }
  }

  void _showFullScreenImage(String imageId, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DraggableDismissNetworkImage(
            animation: animation,
            imageUrl: imageUrl,
            imageId: imageId,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showExistingImageModal(
    String imageId,
    String? initialImageUrl,
    String? extractedText, {
    int? pageNumber,
  }) {
    showExistingImageModal(
      context: context,
      imageId: imageId,
      initialImageUrl: initialImageUrl,
      initialExtractedText: extractedText,
      pageNumber: pageNumber,
      totalPages: _currentBook.totalPages,
      cachedEditedText: _editedTexts[imageId],
      onFullScreenImage: (imageId, imageUrl) {
        if (imageUrl != null) {
          _showFullScreenImage(imageId, imageUrl);
        }
      },
      onDeleteImage: (imageId, imageUrl, {bool dismissParentOnDelete = false}) {
        _confirmDeleteImage(imageId, imageUrl, dismissParentOnDelete: dismissParentOnDelete);
      },
      onReExtractText: ({
        required String imageUrl,
        required void Function(String extractedText) onConfirm,
      }) {
        if (!mounted) return;
        reExtractTextFromImage(context, imageUrl: imageUrl, onConfirm: onConfirm);
      },
      onReplaceImage: ({
        required String imageId,
        required String currentText,
        required void Function(String? newImageUrl) onReplaced,
      }) {
        _showReplaceImageOptionsOverModal(
          imageId: imageId,
          currentText: currentText,
          onReplaced: onReplaced,
        );
      },
      onSave: ({
        required String imageId,
        required String extractedText,
        required int? pageNumber,
      }) async {
        try {
          await Supabase.instance.client
              .from('book_images')
              .update({
                'extracted_text': extractedText,
                'page_number': pageNumber,
              })
              .eq('id', imageId);
          _editedTexts.remove(imageId);
          _cachedImages = null;
          _bookImagesFuture = fetchBookImages(_currentBook.id!);
          if (mounted) {
            setState(() {});
          }
          return true;
        } catch (e) {
          return false;
        }
      },
      onTextEdited: (imageId, text) {
        _editedTexts[imageId] = text;
      },
    );
  }

  void _showDailyTargetChangeDialog() async {
    await DailyTargetDialog.show(
      context: context,
      book: _currentBook,
      pagesLeft: _pagesLeft,
      daysLeft: _daysLeft,
      onSave: (newDailyTarget) {
        setState(() {
          _currentBook = _currentBook.copyWith(
            dailyTargetPages: newDailyTarget,
          );
        });
      },
    );
  }

  void _showUpdateTargetDateDialogWithConfirm() async {
    await UpdateTargetDateDialog.show(
      context: context,
      currentTargetDate: _currentBook.targetDate,
      nextAttemptCount: _attemptCount + 1,
      onConfirm: _updateTargetDate,
    );
  }

  Future<void> _updateTargetDate(DateTime newDate, int newAttempt) async {
    final updatedBook = _currentBook.copyWith(
      targetDate: newDate,
      attemptCount: newAttempt,
    );
    final result = await _bookService.updateBook(_currentBook.id!, updatedBook);

    if (result != null && mounted) {
      setState(() {
        _currentBook = result;
        _attemptCount = newAttempt;
      });

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );

      CustomSnackbar.show(
        context,
        message: '$newAttempt번째 도전 시작! D-$_daysLeft',
        type: SnackbarType.info,
        icon: Icons.flag,
      );
    }
  }
}
