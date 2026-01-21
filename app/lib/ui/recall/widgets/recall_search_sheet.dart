import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/domain/models/recall_models.dart';
import 'package:book_golas/ui/recall/view_model/recall_view_model.dart';

Future<void> showRecallSearchSheet({
  required BuildContext context,
  required String bookId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ChangeNotifierProvider(
      create: (_) => RecallViewModel(),
      child: _RecallSearchSheetContent(bookId: bookId),
    ),
  );
}

class _RecallSearchSheetContent extends StatefulWidget {
  final String bookId;

  const _RecallSearchSheetContent({required this.bookId});

  @override
  State<_RecallSearchSheetContent> createState() =>
      _RecallSearchSheetContentState();
}

class _RecallSearchSheetContentState extends State<_RecallSearchSheetContent> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<RecallViewModel>().search(widget.bookId, query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewModel = context.watch<RecallViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF5B7FFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '내 기록 검색',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.xmark,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '예: "저자가 습관에 대해 뭐라고 했지?"',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _controller.text.isEmpty
                          ? (isDark ? Colors.grey[600] : Colors.grey[400])
                          : const Color(0xFF5B7FFF),
                    ),
                    onPressed: () => _search(_controller.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                ),
                onSubmitted: _search,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (!viewModel.isSearching && viewModel.searchResult == null)
              _buildSuggestedQuestions(isDark),
            Expanded(
              child: _buildContent(viewModel, scrollController, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions(bool isDark) {
    final suggestions = [
      '내가 가장 인상 깊게 본 부분은?',
      '실천하려고 메모한 내용은?',
      '저자의 핵심 메시지는?',
      '내가 공감한 부분은?',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 질문',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((text) {
              return ActionChip(
                label: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.blue[200] : Colors.blue[700],
                  ),
                ),
                backgroundColor: isDark
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.blue[50],
                side: BorderSide.none,
                onPressed: () {
                  _controller.text = text;
                  _search(text);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RecallViewModel viewModel,
      ScrollController scrollController, bool isDark) {
    if (viewModel.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF5B7FFF)),
            const SizedBox(height: 16),
            Text(
              '당신의 기록을 검색하는 중...',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.searchResult != null) {
      return _buildSearchResult(
          viewModel.searchResult!, scrollController, isDark);
    }

    return _buildEmptyState(isDark);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '궁금한 내용을 검색해보세요',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '하이라이트, 메모, 사진 속에서 찾아드립니다',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(RecallSearchResult result,
      ScrollController scrollController, bool isDark) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF5B7FFF).withValues(alpha: 0.15)
                : const Color(0xFF5B7FFF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFF5B7FFF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI 답변',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.answer,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (result.sources.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '관련 기록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...result.sources.map((source) => _buildSourceCard(source, isDark)),
        ],
      ],
    );
  }

  Widget _buildSourceCard(RecallSource source, bool isDark) {
    IconData icon;
    Color color;

    switch (source.type) {
      case 'highlight':
        icon = Icons.highlight;
        color = Colors.amber;
        break;
      case 'note':
        icon = Icons.notes;
        color = Colors.green;
        break;
      case 'photo_ocr':
        icon = Icons.photo;
        color = Colors.purple;
        break;
      default:
        icon = Icons.article;
        color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                source.typeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              if (source.pageNumber != null)
                Text(
                  '${source.pageNumber}페이지',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            source.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          if (source.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${source.createdAt!.year}.${source.createdAt!.month.toString().padLeft(2, '0')}.${source.createdAt!.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
