import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/data/services/ai_content_service.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';
import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';

class BookReviewScreen extends StatefulWidget {
  final Book book;

  const BookReviewScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookReviewScreen> createState() => _BookReviewScreenState();
}

class _BookReviewScreenState extends State<BookReviewScreen> {
  late TextEditingController _reviewController;
  late FocusNode _focusNode;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _reviewController =
        TextEditingController(text: widget.book.longReview ?? '');
    _focusNode = FocusNode();
    _reviewController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _reviewController.removeListener(_onTextChanged);
    _reviewController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _reviewController.text != (widget.book.longReview ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveReview() async {
    if (_isSaving) return;

    final bookId = widget.book.id;
    if (bookId == null) {
      CustomSnackbar.show(
        context,
        message: '책 정보를 찾을 수 없습니다.',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bookService = context.read<BookService>();
      final reviewText = _reviewController.text.trim();
      final updatedBook = await bookService.updateLongReview(
        bookId,
        reviewText.isEmpty ? null : reviewText,
      );

      if (!mounted) return;

      if (updatedBook != null) {
        CustomSnackbar.show(
          context,
          message: '독후감이 저장되었습니다.',
          type: SnackbarType.success,
          icon: CupertinoIcons.checkmark_circle,
        );
        Navigator.pop(context, true);
      } else {
        CustomSnackbar.show(
          context,
          message: '저장에 실패했습니다. 다시 시도해주세요.',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      debugPrint('Failed to save review: $e');
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '저장 중 오류가 발생했습니다.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateAIDraft() async {
    if (_isGeneratingAI) return;

    final bookId = widget.book.id;
    if (bookId == null) {
      CustomSnackbar.show(
        context,
        message: '책 정보를 찾을 수 없습니다.',
        type: SnackbarType.error,
      );
      return;
    }

    if (_reviewController.text.trim().isNotEmpty) {
      final shouldReplace = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('AI 초안 생성'),
          content: const Text('현재 작성 중인 내용이 있습니다.\nAI 초안으로 대체하시겠습니까?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('대체하기'),
            ),
          ],
        ),
      );

      if (shouldReplace != true) return;
    }

    setState(() {
      _isGeneratingAI = true;
    });

    try {
      final aiService = AIContentService();
      final draft = await aiService.generateBookReviewDraft(bookId: bookId);

      if (!mounted) return;

      if (draft != null && draft.isNotEmpty) {
        _reviewController.text = draft;
        CustomSnackbar.show(
          context,
          message: 'AI 초안이 생성되었습니다. 자유롭게 수정해주세요!',
          type: SnackbarType.success,
          icon: CupertinoIcons.sparkles,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: 'AI 초안 생성에 실패했습니다. 다시 시도해주세요.',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      debugPrint('Failed to generate AI draft: $e');
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'AI 초안 생성 중 오류가 발생했습니다.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('변경 사항 삭제'),
        content: const Text('저장하지 않은 내용이 있습니다.\n정말 나가시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.xmark,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            '독후감',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _hasChanges && !_isSaving ? _saveReview : null,
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _hasChanges
                            ? AppColors.primary
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookInfo(isDark),
                const SizedBox(height: 16),
                _buildAIButton(isDark),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildReviewTextField(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookInfo(bool isDark) {
    return Row(
      children: [
        if (widget.book.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.book.imageUrl!,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.book.author != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.book.author!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIButton(bool isDark) {
    return GestureDetector(
      onTap: _isGeneratingAI ? null : _generateAIDraft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGeneratingAI) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI가 초안을 작성하고 있어요...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ] else ...[
              Icon(
                CupertinoIcons.sparkles,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI로 독후감 초안 작성하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTextField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _reviewController,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: '이 책을 읽고 느낀 점, 인상 깊었던 부분, 나에게 준 영감 등을 자유롭게 적어보세요.',
          hintStyle: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
            height: 1.6,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
