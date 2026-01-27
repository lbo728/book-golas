import 'package:flutter/material.dart';
import 'package:book_golas/domain/models/note_structure_models.dart';

class NoteStructureMindmap extends StatelessWidget {
  final NoteStructure? structure;

  const NoteStructureMindmap({
    super.key,
    required this.structure,
  });

  @override
  Widget build(BuildContext context) {
    if (structure == null || structure!.clusters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '독서 기록이 부족합니다.\n최소 5개 이상의 하이라이트나 메모가 필요합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 2.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: structure!.clusters
              .map((cluster) => _buildCluster(context, cluster))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCluster(BuildContext context, Cluster cluster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cluster.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cluster.summary,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                cluster.nodes.map((node) => _buildNode(context, node)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context, Node node) {
    Color nodeColor;
    switch (node.type) {
      case 'highlight':
        nodeColor = Colors.blue.shade50;
        break;
      case 'note':
        nodeColor = Colors.green.shade50;
        break;
      case 'photo_ocr':
        nodeColor = Colors.orange.shade50;
        break;
      default:
        nodeColor = Colors.grey.shade50;
    }

    return GestureDetector(
      onTap: () => _showNodeDetail(context, node),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          node.content.length > 30
              ? '${node.content.substring(0, 30)}...'
              : node.content,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _showNodeDetail(BuildContext context, Node node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    node.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (node.pageNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '페이지: ${node.pageNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              node.content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
