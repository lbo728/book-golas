import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/note_structure_models.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

class NoteStructureMindmap extends StatelessWidget {
  final NoteStructure? structure;

  const NoteStructureMindmap({
    super.key,
    required this.structure,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (structure == null || structure!.clusters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            '독서 기록이 부족합니다.\n최소 5개 이상의 하이라이트나 메모가 필요합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: structure!.clusters
            .map((cluster) => _buildCluster(context, cluster, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildCluster(BuildContext context, Cluster cluster, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isDark ? BLabColors.surfaceDark : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cluster.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cluster.summary,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cluster.nodes
                .map((node) => _buildNode(context, node, isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context, Node node, bool isDark) {
    Color nodeColor;
    Color textColor;
    Color borderColor;

    switch (node.type) {
      case 'highlight':
        nodeColor = isDark
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.amber.withValues(alpha: 0.15);
        textColor = isDark ? Colors.amber[300]! : Colors.amber[800]!;
        borderColor = isDark ? Colors.amber[700]! : Colors.amber[300]!;
        break;
      case 'note':
        nodeColor = isDark
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.green.withValues(alpha: 0.15);
        textColor = isDark ? Colors.green[300]! : Colors.green[800]!;
        borderColor = isDark ? Colors.green[700]! : Colors.green[300]!;
        break;
      case 'photo_ocr':
        nodeColor = isDark
            ? Colors.purple.withValues(alpha: 0.2)
            : Colors.purple.withValues(alpha: 0.15);
        textColor = isDark ? Colors.purple[300]! : Colors.purple[800]!;
        borderColor = isDark ? Colors.purple[700]! : Colors.purple[300]!;
        break;
      default:
        nodeColor = isDark
            ? Colors.grey.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.15);
        textColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
        borderColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: () => _showNodeDetail(context, node, isDark),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          node.content.length > 40
              ? '${node.content.substring(0, 40)}...'
              : node.content,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showNodeDetail(BuildContext context, Node node, bool isDark) {
    Color badgeColor;
    Color badgeTextColor;
    String badgeLabel;

    switch (node.type) {
      case 'highlight':
        badgeColor = isDark ? Colors.amber[800]! : Colors.amber;
        badgeTextColor = isDark ? Colors.white : Colors.black;
        badgeLabel = '하이라이트';
        break;
      case 'note':
        badgeColor = isDark ? Colors.green[700]! : Colors.green;
        badgeTextColor = Colors.white;
        badgeLabel = '메모';
        break;
      case 'photo_ocr':
        badgeColor = isDark ? Colors.purple[700]! : Colors.purple;
        badgeTextColor = Colors.white;
        badgeLabel = '사진 OCR';
        break;
      default:
        badgeColor = isDark ? Colors.grey[700]! : Colors.grey;
        badgeTextColor = Colors.white;
        badgeLabel = node.type;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? BLabColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더 (뱃지 + 페이지 정보)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    if (node.pageNumber != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'p.${node.pageNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                height: 1,
              ),
              // 본문 (스크롤 가능)
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    node.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
