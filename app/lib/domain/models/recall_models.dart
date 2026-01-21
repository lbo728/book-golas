class RecallSource {
  final String type;
  final String content;
  final int? pageNumber;
  final String? sourceId;
  final DateTime? createdAt;

  RecallSource({
    required this.type,
    required this.content,
    this.pageNumber,
    this.sourceId,
    this.createdAt,
  });

  factory RecallSource.fromJson(Map<String, dynamic> json) {
    return RecallSource(
      type: json['type'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int?,
      sourceId: json['sourceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'highlight':
        return '하이라이트';
      case 'note':
        return '메모';
      case 'photo_ocr':
        return '사진';
      default:
        return type;
    }
  }
}

class RecallSearchResult {
  final String answer;
  final List<RecallSource> sources;

  RecallSearchResult({
    required this.answer,
    required this.sources,
  });

  factory RecallSearchResult.fromJson(Map<String, dynamic> json) {
    return RecallSearchResult(
      answer: json['answer'] as String,
      sources: (json['sources'] as List)
          .map((s) => RecallSource.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
