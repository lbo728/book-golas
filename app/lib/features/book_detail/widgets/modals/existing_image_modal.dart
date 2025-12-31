import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import 'package:book_golas/core/widgets/custom_snackbar.dart';
import 'package:book_golas/core/widgets/keyboard_accessory_bar.dart';
import 'package:book_golas/data/services/image_cache_manager.dart';

class ExistingImageModal extends StatefulWidget {
  final String imageId;
  final String? initialImageUrl;
  final String? initialExtractedText;
  final int? pageNumber;
  final int totalPages;
  final String? cachedEditedText;
  final void Function(String imageId, String? imageUrl) onFullScreenImage;
  final void Function(String imageId, String? imageUrl, {bool dismissParentOnDelete}) onDeleteImage;
  final void Function({
    required String imageUrl,
    required void Function(String extractedText) onConfirm,
  }) onReExtractText;
  final void Function({
    required String imageId,
    required String currentText,
    required void Function(String? newImageUrl) onReplaced,
  }) onReplaceImage;
  final Future<bool> Function({
    required String imageId,
    required String extractedText,
    required int? pageNumber,
  }) onSave;
  final void Function(String imageId, String text) onTextEdited;

  const ExistingImageModal({
    super.key,
    required this.imageId,
    this.initialImageUrl,
    this.initialExtractedText,
    this.pageNumber,
    required this.totalPages,
    this.cachedEditedText,
    required this.onFullScreenImage,
    required this.onDeleteImage,
    required this.onReExtractText,
    required this.onReplaceImage,
    required this.onSave,
    required this.onTextEdited,
  });

  @override
  State<ExistingImageModal> createState() => _ExistingImageModalState();
}

class _ExistingImageModalState extends State<ExistingImageModal> {
  late TextEditingController _textController;
  late TextEditingController _pageNumberController;
  final _focusNode = FocusNode();
  final _pageNumberFocusNode = FocusNode();

  late String _originalText;
  late String? _imageUrl;
  late int? _editingPageNumber;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _hideKeyboardAccessory = false;
  bool _pageNumberError = false;
  bool _hasShownPageError = false;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _originalText =
        widget.cachedEditedText ?? widget.initialExtractedText ?? '';
    _textController = TextEditingController(text: _originalText);
    _pageNumberController = TextEditingController(
      text: widget.pageNumber?.toString() ?? '',
    );
    _imageUrl = widget.initialImageUrl;
    _editingPageNumber = widget.pageNumber;
  }

  @override
  void dispose() {
    widget.onTextEdited(widget.imageId, _textController.text);
    _textController.dispose();
    _pageNumberController.dispose();
    _focusNode.dispose();
    _pageNumberFocusNode.dispose();
    super.dispose();
  }

  void _showCancelConfirmation(bool isDark) {
    final hasTextChanges = _textController.text != _originalText;
    final hasPageChanges = _editingPageNumber != widget.pageNumber;

    if (hasTextChanges || hasPageChanges) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (bottomSheetContext) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    '수정 중인 내용이 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              _textController.text = _originalText;
                              _editingPageNumber = widget.pageNumber;
                              _pageNumberController.text =
                                  widget.pageNumber?.toString() ?? '';
                              _isEditing = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '변경사항 무시',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(bottomSheetContext),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B7FFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '이어서 하기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(bottomSheetContext).padding.bottom + 8,
                  ),
                ],
              ),
            ),
      );
    } else {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _handlePageNumberChange(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > widget.totalPages) {
      if (!_hasShownPageError) {
        HapticFeedback.vibrate();
        CustomSnackbar.show(
          context,
          message: '총 페이지 수(${widget.totalPages})를 초과할 수 없습니다',
          type: SnackbarType.error,
          rootOverlay: true,
          aboveKeyboard: true,
        );
        _hasShownPageError = true;
      }
      setState(() {
        _pageNumberError = true;
        _editingPageNumber = parsed;
      });
    } else {
      _hasShownPageError = false;
      setState(() {
        _pageNumberError = false;
        _editingPageNumber = parsed;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final success = await widget.onSave(
        imageId: widget.imageId,
        extractedText: _textController.text,
        pageNumber: _editingPageNumber,
      );
      if (success && mounted) {
        Navigator.pop(context);
        CustomSnackbar.show(context, message: '저장되었습니다', type: SnackbarType.success);
      } else {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_listenerAdded) {
      _listenerAdded = true;
      _focusNode.addListener(() => setState(() {}));
      _pageNumberFocusNode.addListener(() => setState(() {}));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultModalHeight = screenHeight * 0.85;
    final availableHeight = screenHeight - statusBarHeight - keyboardHeight;
    final modalHeight =
        isKeyboardOpen
            ? availableHeight.clamp(0.0, defaultModalHeight)
            : defaultModalHeight;

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isEditing) {
          _showCancelConfirmation(isDark);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_isEditing) {
            _focusNode.unfocus();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: keyboardHeight,
            top: statusBarHeight,
          ),
          child: Stack(
            children: [
              Container(
                height: modalHeight,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildDragHandle(isDark),
                    _buildHeader(isDark),
                    Expanded(
                      child:
                          hasImage
                              ? _buildWithImageContent(isDark)
                              : _buildTextOnlyContent(isDark),
                    ),
                  ],
                ),
              ),
              if (_isEditing &&
                  isKeyboardOpen &&
                  (_focusNode.hasFocus || _pageNumberFocusNode.hasFocus) &&
                  !_hideKeyboardAccessory)
                _buildKeyboardAccessory(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          final hasTextChanges = _textController.text != _originalText;
          final hasPageChanges = _editingPageNumber != widget.pageNumber;
          if (_isEditing && (hasTextChanges || hasPageChanges)) {
            _showCancelConfirmation(isDark);
          } else {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed:
                _isEditing
                    ? () => _showCancelConfirmation(isDark)
                    : () => Navigator.pop(context),
            child: Text(
              _isEditing ? '취소' : '닫기',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          if (_isEditing)
            _buildPageNumberEditor(isDark)
          else
            Text(
              _editingPageNumber != null
                  ? 'p.$_editingPageNumber'
                  : '페이지 미설정',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: (_isSaving || _pageNumberError) ? null : _handleSave,
              child: Text(
                _isSaving ? '저장 중...' : '저장',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isSaving ? Colors.grey : const Color(0xFF5B7FFF),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                widget.onDeleteImage(
                  widget.imageId,
                  _imageUrl,
                  dismissParentOnDelete: true,
                );
              },
              child: Text(
                '삭제',
                style: TextStyle(fontSize: 16, color: Colors.red[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageNumberEditor(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'p.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 70,
          height: 32,
          child: TextField(
            controller: _pageNumberController,
            focusNode: _pageNumberFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color:
                  _pageNumberError
                      ? Colors.red
                      : (isDark ? Colors.white : Colors.black),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _pageNumberError ? Colors.red : Colors.grey[400]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _pageNumberError ? Colors.red : Colors.grey[400]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color:
                      _pageNumberError ? Colors.red : const Color(0xFF5B7FFF),
                ),
              ),
            ),
            onChanged: _handlePageNumberChange,
          ),
        ),
      ],
    );
  }

  Widget _buildWithImageContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePreview(isDark),
          const SizedBox(height: 20),
          _buildTextHeader(isDark),
          const SizedBox(height: 12),
          _buildTextContent(isDark, minHeight: 150),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextOnlyContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isEditing) _buildTextActions(isDark),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildExpandedTextContent(isDark)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return GestureDetector(
      onTap: () => widget.onFullScreenImage(widget.imageId, _imageUrl),
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'book_image_${widget.imageId}',
                child: CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  cacheManager: BookImageCacheManager.instance,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor:
                            isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        highlightColor:
                            isDark ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          CupertinoIcons.photo,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildExtractTextButton(),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: _buildReplaceImageButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractTextButton() {
    return GestureDetector(
      onTap: () {
        widget.onReExtractText(
          imageUrl: _imageUrl!,
          onConfirm: (extractedOcrText) {
            setState(() {
              _textController.text = extractedOcrText;
            });
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_outlined, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '텍스트 추출',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplaceImageButton() {
    return GestureDetector(
      onTap: () {
        widget.onReplaceImage(
          imageId: widget.imageId,
          currentText: _textController.text,
          onReplaced: (newImageUrl) {
            if (newImageUrl != null) {
              setState(() {
                _imageUrl = newImageUrl;
              });
            }
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.arrow_2_squarepath, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text('교체하기', style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '인상적인 문구',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        if (!_isEditing)
          _buildTextActions(isDark)
        else
          _buildClearButton(),
      ],
    );
  }

  Widget _buildTextActions(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (_textController.text.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: _textController.text));
              CustomSnackbar.show(
                context,
                message: '텍스트가 복사되었습니다.',
                rootOverlay: true,
                bottomOffset: 40,
              );
            }
          },
          child: Row(
            children: [
              Icon(
                CupertinoIcons.doc_on_clipboard,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '복사하기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _isEditing = true;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _focusNode.requestFocus();
            });
          },
          child: const Row(
            children: [
              Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFF5B7FFF)),
              SizedBox(width: 4),
              Text(
                '수정하기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5B7FFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () => setState(() => _textController.clear()),
      child: Row(
        children: [
          Icon(CupertinoIcons.trash, size: 14, color: Colors.red[400]),
          const SizedBox(width: 4),
          Text(
            '모두 지우기',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(bool isDark, {required double minHeight}) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color:
            (_isEditing || _textController.text.isNotEmpty)
                ? (isDark ? Colors.grey[900] : Colors.grey[100])
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            (_isEditing || _textController.text.isNotEmpty)
                ? Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                )
                : null,
      ),
      child:
          _isEditing
              ? TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '텍스트를 입력하세요...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16),
                child:
                    _textController.text.isEmpty
                        ? Text(
                          '인상적인 문구가 없습니다.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        )
                        : SelectableText(
                          _textController.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
              ),
    );
  }

  Widget _buildExpandedTextContent(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            _isEditing
                ? (isDark ? Colors.grey[900] : Colors.grey[100])
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            _isEditing
                ? Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                )
                : null,
      ),
      child:
          _isEditing
              ? TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '텍스트를 입력하세요...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child:
                    _textController.text.isEmpty
                        ? Text(
                          '인상적인 문구가 없습니다.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        )
                        : SelectableText(
                          _textController.text,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.8,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
              ),
    );
  }

  Widget _buildKeyboardAccessory(bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: KeyboardAccessoryBar(
        isDark: isDark,
        showNavigation: true,
        icon: CupertinoIcons.checkmark,
        onUp: () {
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
            _pageNumberFocusNode.requestFocus();
          }
        },
        onDown: () {
          if (_pageNumberFocusNode.hasFocus) {
            _pageNumberFocusNode.unfocus();
            _focusNode.requestFocus();
          }
        },
        onDone: () {
          setState(() {
            _hideKeyboardAccessory = true;
          });
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
          } else {
            _pageNumberFocusNode.unfocus();
          }
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _hideKeyboardAccessory = false;
              });
            }
          });
        },
      ),
    );
  }
}

void showExistingImageModal({
  required BuildContext context,
  required String imageId,
  String? initialImageUrl,
  String? initialExtractedText,
  int? pageNumber,
  required int totalPages,
  String? cachedEditedText,
  required void Function(String imageId, String? imageUrl) onFullScreenImage,
  required void Function(String imageId, String? imageUrl, {bool dismissParentOnDelete}) onDeleteImage,
  required void Function({
    required String imageUrl,
    required void Function(String extractedText) onConfirm,
  }) onReExtractText,
  required void Function({
    required String imageId,
    required String currentText,
    required void Function(String? newImageUrl) onReplaced,
  }) onReplaceImage,
  required Future<bool> Function({
    required String imageId,
    required String extractedText,
    required int? pageNumber,
  }) onSave,
  required void Function(String imageId, String text) onTextEdited,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder:
        (modalContext) => ExistingImageModal(
          imageId: imageId,
          initialImageUrl: initialImageUrl,
          initialExtractedText: initialExtractedText,
          pageNumber: pageNumber,
          totalPages: totalPages,
          cachedEditedText: cachedEditedText,
          onFullScreenImage: onFullScreenImage,
          onDeleteImage: onDeleteImage,
          onReExtractText: onReExtractText,
          onReplaceImage: onReplaceImage,
          onSave: onSave,
          onTextEdited: onTextEdited,
        ),
  );
}
