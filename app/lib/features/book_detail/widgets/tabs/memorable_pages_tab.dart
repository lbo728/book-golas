import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:book_golas/data/services/google_vision_ocr_service.dart';
import 'package:book_golas/data/services/image_cache_manager.dart';

class MemorablePagesTab extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> imagesFuture;
  final List<Map<String, dynamic>>? cachedImages;
  final String sortMode;
  final bool isSelectionMode;
  final Set<String> selectedImageIds;
  final void Function(String sortMode) onSortModeChanged;
  final void Function(bool isSelectionMode) onSelectionModeChanged;
  final void Function(String imageId, bool isSelected) onImageSelected;
  final VoidCallback onDeleteSelected;
  final void Function(String imageId, String? imageUrl, String? extractedText, int? pageNumber) onImageTap;
  final void Function(List<Map<String, dynamic>> images) onImagesLoaded;

  const MemorablePagesTab({
    super.key,
    required this.imagesFuture,
    this.cachedImages,
    required this.sortMode,
    required this.isSelectionMode,
    required this.selectedImageIds,
    required this.onSortModeChanged,
    required this.onSelectionModeChanged,
    required this.onImageSelected,
    required this.onDeleteSelected,
    required this.onImageTap,
    required this.onImagesLoaded,
  });

  @override
  State<MemorablePagesTab> createState() => _MemorablePagesTabState();
}

class _MemorablePagesTabState extends State<MemorablePagesTab> {
  final GoogleVisionOcrService _ocrService = GoogleVisionOcrService();

  List<Map<String, dynamic>> _sortImages(List<Map<String, dynamic>> images) {
    final sorted = List<Map<String, dynamic>>.from(images);
    sorted.sort((a, b) {
      switch (widget.sortMode) {
        case 'page_asc':
          final pageA = a['page_number'] as int? ?? 0;
          final pageB = b['page_number'] as int? ?? 0;
          return pageA.compareTo(pageB);
        case 'page_desc':
          final pageA = a['page_number'] as int? ?? 0;
          final pageB = b['page_number'] as int? ?? 0;
          return pageB.compareTo(pageA);
        case 'date_asc':
          final dateA = a['created_at'] as String? ?? '';
          final dateB = b['created_at'] as String? ?? '';
          return dateA.compareTo(dateB);
        case 'date_desc':
        default:
          final dateA = a['created_at'] as String? ?? '';
          final dateB = b['created_at'] as String? ?? '';
          return dateB.compareTo(dateA);
      }
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.imagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            widget.cachedImages == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          widget.onImagesLoaded(snapshot.data!);
        }

        final rawImages = widget.cachedImages ?? snapshot.data ?? [];
        final images = _sortImages(rawImages);

        if (images.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          children: [
            _buildToolbar(isDark),
            Expanded(child: _buildImageList(images, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '아직 추가된 사진이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '하단 + 버튼으로 추가해보세요',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isSelectionMode)
            Text(
              '${widget.selectedImageIds.length}개 선택됨',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          else
            _buildSortButton(isDark),
          _buildActionButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildSortButton(bool isDark) {
    return PopupMenuButton<String>(
      onSelected: widget.onSortModeChanged,
      itemBuilder: (context) => [
        _buildSortMenuItem('page_desc', '페이지 높은순'),
        _buildSortMenuItem('page_asc', '페이지 낮은순'),
        _buildSortMenuItem('date_desc', '최근 기록순'),
        _buildSortMenuItem('date_asc', '오래된 기록순'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.arrow_up_arrow_down,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              widget.sortMode.contains('page') ? '페이지' : '날짜',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (widget.sortMode == value)
            const Icon(Icons.check, size: 18, color: Color(0xFF5B7FFF))
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        if (widget.isSelectionMode && widget.selectedImageIds.isNotEmpty)
          TextButton.icon(
            onPressed: widget.onDeleteSelected,
            icon: const Icon(
              CupertinoIcons.trash,
              size: 18,
              color: Color(0xFFFF3B30),
            ),
            label: const Text(
              '삭제',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            if (widget.isSelectionMode) {
              for (final id in widget.selectedImageIds.toList()) {
                widget.onImageSelected(id, false);
              }
            }
            widget.onSelectionModeChanged(!widget.isSelectionMode);
          },
          child: Text(
            widget.isSelectionMode ? '완료' : '선택',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B7FFF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageList(List<Map<String, dynamic>> images, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 100),
      itemCount: images.length,
      itemBuilder: (context, index) => _buildImageItem(images[index], isDark),
    );
  }

  Widget _buildImageItem(Map<String, dynamic> image, bool isDark) {
    final imageId = image['id'] as String;
    final imageUrl = image['image_url'] as String?;
    final extractedText = image['extracted_text'] as String?;
    final pageNumber = image['page_number'] as int?;
    final createdAt = image['created_at'] as String?;
    final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;
    final previewText = _ocrService.getPreviewText(extractedText, maxLines: 2);
    final isSelected = widget.selectedImageIds.contains(imageId);

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.month}/${date.day}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          widget.onImageSelected(imageId, !isSelected);
        } else {
          widget.onImageTap(imageId, imageUrl, extractedText, pageNumber);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImageUrl) _buildThumbnail(imageId, imageUrl!, isDark),
                _buildTextContent(
                  previewText: previewText,
                  pageNumber: pageNumber,
                  formattedDate: formattedDate,
                  hasImageUrl: hasImageUrl,
                  isDark: isDark,
                ),
                _buildTrailingIcon(isSelected, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String imageId, String imageUrl, bool isDark) {
    return Hero(
      tag: 'book_image_$imageId',
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: SizedBox(
          width: 80,
          height: 80,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: BookImageCacheManager.instance,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                CupertinoIcons.photo,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent({
    required String previewText,
    required int? pageNumber,
    required String formattedDate,
    required bool hasImageUrl,
    required bool isDark,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          left: hasImageUrl ? 12 : 16,
          right: 8,
          top: 12,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              previewText.isNotEmpty ? previewText : '탭하여 상세 보기',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: previewText.isNotEmpty
                    ? (isDark ? Colors.grey[300] : Colors.grey[800])
                    : (isDark ? Colors.grey[500] : Colors.grey[500]),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (pageNumber != null || formattedDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (pageNumber != null)
                    Text(
                      'p.$pageNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (pageNumber != null && formattedDate.isNotEmpty)
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  if (formattedDate.isNotEmpty)
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingIcon(bool isSelected, bool isDark) {
    if (widget.isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFF5B7FFF) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B7FFF)
                  : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }
}
