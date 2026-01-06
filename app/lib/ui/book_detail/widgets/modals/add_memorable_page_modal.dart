import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';
import 'package:book_golas/ui/core/widgets/keyboard_accessory_bar.dart';

class AddMemorablePageModal extends StatefulWidget {
  final Uint8List? initialImageBytes;
  final String initialExtractedText;
  final int? initialPageNumber;
  final int totalPages;
  final void Function(Uint8List imageBytes) onImageTap;
  final void Function(void Function(Uint8List?, String, int?) onImageSelected)
      onShowImageSourceSheet;
  final void Function(VoidCallback onConfirm) onShowReplaceImageConfirmation;
  final void Function(
    Uint8List imageBytes,
    void Function(String ocrText, int? pageNumber) onResult,
  ) onExtractText;
  final Future<bool> Function({
    Uint8List? imageBytes,
    required String extractedText,
    int? pageNumber,
  }) onUpload;
  final void Function(Uint8List? imageBytes, String text, int? pageNumber)?
      onStateChanged;

  const AddMemorablePageModal({
    super.key,
    this.initialImageBytes,
    this.initialExtractedText = '',
    this.initialPageNumber,
    required this.totalPages,
    required this.onImageTap,
    required this.onShowImageSourceSheet,
    required this.onShowReplaceImageConfirmation,
    required this.onExtractText,
    required this.onUpload,
    this.onStateChanged,
  });

  @override
  State<AddMemorablePageModal> createState() => _AddMemorablePageModalState();
}

class _AddMemorablePageModalState extends State<AddMemorablePageModal> {
  late Uint8List? _fullImageBytes;
  late TextEditingController _textController;
  late TextEditingController _pageController;
  final _textFocusNode = FocusNode();
  final _pageFocusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _isUploading = false;
  String? _pageValidationError;
  bool _hasShownPageError = false;
  bool _hideKeyboardAccessory = false;
  bool _uploadSuccess = false;
  int? _pageNumber;

  @override
  void initState() {
    super.initState();
    _fullImageBytes = widget.initialImageBytes;
    _textController = TextEditingController(text: widget.initialExtractedText);
    _pageController = TextEditingController(
      text:
          widget.initialPageNumber != null
              ? widget.initialPageNumber.toString()
              : '',
    );
    _pageNumber = widget.initialPageNumber;
  }

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    _textFocusNode.dispose();
    _pageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCancelConfirmation(bool isDark) {
    final hasChanges =
        _fullImageBytes != null ||
        _textController.text.isNotEmpty ||
        _pageController.text.isNotEmpty;

    if (hasChanges) {
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
                    '변경 중인 사항이 취소됩니다.\n닫으시겠어요?',
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
                          onTap: () => Navigator.pop(bottomSheetContext),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '취소',
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
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            _uploadSuccess = true;
                            Navigator.pop(context, {'clear': true});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '닫기',
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
      Navigator.pop(context);
    }
  }

  void _showExtractTextConfirmation(bool isDark) {
    showModalBottomSheet<bool>(
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
                  '텍스트를 추출하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '작성하신 텍스트를 덮어씁니다.\n크레딧을 소모합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(bottomSheetContext, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(bottomSheetContext, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B7FFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '추출하기',
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
    ).then((shouldProceed) {
      if (shouldProceed == true && _fullImageBytes != null) {
        widget.onExtractText(_fullImageBytes!, (ocrText, extractedPageNum) {
          setState(() {
            _textController.text = ocrText;
            if (extractedPageNum != null) {
              _pageNumber = extractedPageNum;
              _pageController.text = extractedPageNum.toString();
            }
          });
          _notifyStateChanged();
        });
      }
    });
  }

  void _handlePageNumberChange(String value) {
    if (value.isEmpty) {
      setState(() {
        _pageNumber = null;
        _pageValidationError = null;
        _hasShownPageError = false;
      });
      _notifyStateChanged();
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed != null) {
      if (parsed > widget.totalPages) {
        if (!_hasShownPageError) {
          HapticFeedback.heavyImpact();
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
          _pageNumber = parsed;
          _pageValidationError = '전체 페이지 수를 초과할 수 없습니다.';
        });
      } else {
        setState(() {
          _pageNumber = parsed;
          _pageValidationError = null;
          _hasShownPageError = false;
        });
      }
      _notifyStateChanged();
    }
  }

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    final success = await widget.onUpload(
      imageBytes: _fullImageBytes,
      extractedText: _textController.text,
      pageNumber: int.tryParse(_pageController.text),
    );
    if (success && mounted) {
      _uploadSuccess = true;
      Navigator.pop(context, {'clear': true});
    } else {
      setState(() => _isUploading = false);
    }
  }

  bool get _canUpload =>
      _textController.text.isNotEmpty &&
      _pageController.text.isNotEmpty &&
      _pageValidationError == null;

  Map<String, dynamic> _getCurrentState() {
    return {
      'imageBytes': _fullImageBytes,
      'text': _textController.text,
      'pageNumber': int.tryParse(_pageController.text),
    };
  }

  void _notifyStateChanged() {
    widget.onStateChanged?.call(
      _fullImageBytes,
      _textController.text,
      int.tryParse(_pageController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_uploadSuccess) {
          Navigator.pop(context, null);
        } else {
          Navigator.pop(context, _getCurrentState());
        }
      },
      child: GestureDetector(
      onTap: () {
        _textFocusNode.unfocus();
        _pageFocusNode.unfocus();
      },
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Stack(
            children: [
              Container(
                height:
                    MediaQuery.of(context).size.height * 0.85 -
                    MediaQuery.of(context).padding.top,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 12 + MediaQuery.of(context).padding.top),
                    _buildDragHandle(),
                    _buildHeader(isDark),
                    Expanded(child: _buildContent(isDark)),
                  ],
                ),
              ),
              if (!isKeyboardOpen && !_isUploading)
                _buildUploadButton(isDark),
              if (isKeyboardOpen &&
                  (_textFocusNode.hasFocus || _pageFocusNode.hasFocus) &&
                  !_hideKeyboardAccessory)
                _buildKeyboardAccessory(isDark),
              if (_isUploading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _showCancelConfirmation(isDark),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                CupertinoIcons.xmark,
                size: 22,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Text(
            '기록 추가',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(isDark),
          const SizedBox(height: 20),
          _buildPageNumberSection(isDark),
          const SizedBox(height: 20),
          _buildTextSection(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child:
          _fullImageBytes != null
              ? _buildImagePreview(isDark)
              : _buildImagePlaceholder(isDark),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return GestureDetector(
      onTap: () => widget.onImageTap(_fullImageBytes!),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _fullImageBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showExtractTextConfirmation(isDark),
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
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '텍스트 추출',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                widget.onShowReplaceImageConfirmation(() {
                  widget.onShowImageSourceSheet((
                    imageBytes,
                    ocrText,
                    ocrPageNumber,
                  ) {
                    setState(() {
                      _fullImageBytes = imageBytes;
                      if (ocrText.isNotEmpty) {
                        _textController.text = ocrText;
                      }
                      if (ocrPageNumber != null) {
                        _pageController.text = ocrPageNumber.toString();
                      }
                    });
                    _notifyStateChanged();
                  });
                });
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
                    Icon(
                      CupertinoIcons.arrow_2_squarepath,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '교체하기',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => widget.onShowImageSourceSheet((
            imageBytes,
            ocrText,
            ocrPageNumber,
          ) {
            setState(() {
              _fullImageBytes = imageBytes;
              if (ocrText.isNotEmpty) {
                _textController.text = ocrText;
              }
              if (ocrPageNumber != null) {
                _pageController.text = ocrPageNumber.toString();
              }
            });
            _notifyStateChanged();
          }),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.camera,
              size: 40,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '터치하여 이미지 추가',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(선택사항)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumberSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.book,
              size: 16,
              color:
                  _pageValidationError != null
                      ? Colors.red[400]
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              '페이지 수',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    _pageValidationError != null
                        ? Colors.red[400]
                        : (isDark ? Colors.white : Colors.black),
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _pageController,
                focusNode: _pageFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _pageValidationError != null
                          ? Colors.red[400]
                          : (isDark ? Colors.white : Colors.black),
                ),
                onChanged: _handlePageNumberChange,
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          _pageValidationError != null
                              ? Colors.red[400]!
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          _pageValidationError != null
                              ? Colors.red[400]!
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          _pageValidationError != null
                              ? Colors.red[400]!
                              : const Color(0xFF5B7FFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '인상적인 문구',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
            if (_textController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _textController.clear();
                  });
                },
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
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              setState(() {});
              _notifyStateChanged();
            },
            onTap: () {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: '인상적인 대목을 기록해보세요.',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(bool isDark) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 32,
      child: GestureDetector(
        onTap: _canUpload ? _handleUpload : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                _canUpload
                    ? const Color(0xFF5B7FFF)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    _canUpload
                        ? const Color(0xFF5B7FFF).withValues(alpha: 0.3)
                        : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '업로드',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    _canUpload
                        ? Colors.white
                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
              ),
            ),
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
          if (_textFocusNode.hasFocus) {
            _textFocusNode.unfocus();
            _pageFocusNode.requestFocus();
          }
        },
        onDown: () {
          if (_pageFocusNode.hasFocus) {
            _pageFocusNode.unfocus();
            _textFocusNode.requestFocus();
          }
        },
        onDone: () {
          setState(() {
            _hideKeyboardAccessory = true;
          });
          _textFocusNode.unfocus();
          _pageFocusNode.unfocus();
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

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF5B7FFF)),
              SizedBox(height: 16),
              Text(
                '업로드 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showAddMemorablePageModal({
  required BuildContext context,
  Uint8List? initialImageBytes,
  String initialExtractedText = '',
  int? initialPageNumber,
  required int totalPages,
  required void Function(Uint8List imageBytes) onImageTap,
  required void Function(void Function(Uint8List?, String, int?) onImageSelected)
      onShowImageSourceSheet,
  required void Function(VoidCallback onConfirm) onShowReplaceImageConfirmation,
  required void Function(
    Uint8List imageBytes,
    void Function(String ocrText, int? pageNumber) onResult,
  ) onExtractText,
  required Future<bool> Function({
    Uint8List? imageBytes,
    required String extractedText,
    int? pageNumber,
  }) onUpload,
  void Function(Uint8List? imageBytes, String text, int? pageNumber)?
      onStateChanged,
}) {
  return showModalBottomSheet<Map<String, dynamic>?>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder:
        (modalContext) => AddMemorablePageModal(
          initialImageBytes: initialImageBytes,
          initialExtractedText: initialExtractedText,
          initialPageNumber: initialPageNumber,
          totalPages: totalPages,
          onImageTap: onImageTap,
          onShowImageSourceSheet: onShowImageSourceSheet,
          onShowReplaceImageConfirmation: onShowReplaceImageConfirmation,
          onExtractText: onExtractText,
          onUpload: onUpload,
          onStateChanged: onStateChanged,
        ),
  );
}
