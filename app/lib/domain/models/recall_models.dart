import 'package:book_golas/l10n/app_localizations.dart';

class RecallSource {
  final String type;
  final String content;
  final int? pageNumber;
  final String? sourceId;
  final DateTime? createdAt;
  final String? bookId;
  final String? bookTitle;

  RecallSource({
    required this.type,
    required this.content,
    this.pageNumber,
    this.sourceId,
    this.createdAt,
    this.bookId,
    this.bookTitle,
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
      bookId: json['bookId'] as String?,
      bookTitle: json['bookTitle'] as String?,
    );
  }

  String getTypeLabel(AppLocalizations l10n) {
    switch (type) {
      case 'highlight':
        return l10n.contentTypeHighlight;
      case 'note':
        return l10n.contentTypeMemo;
      case 'photo_ocr':
        return l10n.contentTypePhoto;
      default:
        return type;
    }
  }

  @Deprecated('Use getTypeLabel(l10n) instead')
  String get typeLabel {
    switch (type) {
      case 'highlight':
        return 'Highlight';
      case 'note':
        return 'Memo';
      case 'photo_ocr':
        return 'Photo';
      default:
        return type;
    }
  }
}

class RecallSearchResult {
  final String answer;
  final List<RecallSource> sources;
  final Map<String, List<RecallSource>>? sourcesByBook;

  RecallSearchResult({
    required this.answer,
    required this.sources,
    this.sourcesByBook,
  });

  factory RecallSearchResult.fromJson(Map<String, dynamic> json) {
    final sourcesByBookJson = json['sourcesByBook'] as Map<String, dynamic>?;
    Map<String, List<RecallSource>>? sourcesByBook;

    if (sourcesByBookJson != null) {
      sourcesByBook = sourcesByBookJson.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((s) => RecallSource.fromJson(s as Map<String, dynamic>))
              .toList(),
        ),
      );
    }

    return RecallSearchResult(
      answer: json['answer'] as String,
      sources: (json['sources'] as List)
          .map((s) => RecallSource.fromJson(s as Map<String, dynamic>))
          .toList(),
      sourcesByBook: sourcesByBook,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'sources': sources
          .map((s) => {
                'type': s.type,
                'content': s.content,
                'pageNumber': s.pageNumber,
                'sourceId': s.sourceId,
                'createdAt': s.createdAt?.toIso8601String(),
                'bookId': s.bookId,
                'bookTitle': s.bookTitle,
              })
          .toList(),
      if (sourcesByBook != null)
        'sourcesByBook': sourcesByBook!.map(
          (key, value) => MapEntry(
            key,
            value
                .map((s) => {
                      'type': s.type,
                      'content': s.content,
                      'pageNumber': s.pageNumber,
                      'sourceId': s.sourceId,
                      'createdAt': s.createdAt?.toIso8601String(),
                      'bookId': s.bookId,
                      'bookTitle': s.bookTitle,
                    })
                .toList(),
          ),
        ),
    };
  }
}

class RecallSearchHistory {
  final String id;
  final String query;
  final String answer;
  final List<RecallSource> sources;
  final DateTime createdAt;

  RecallSearchHistory({
    required this.id,
    required this.query,
    required this.answer,
    required this.sources,
    required this.createdAt,
  });

  factory RecallSearchHistory.fromJson(Map<String, dynamic> json) {
    final sourcesJson = json['sources'];
    List<RecallSource> sources = [];

    if (sourcesJson != null && sourcesJson is List) {
      sources = sourcesJson
          .map((s) => RecallSource.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return RecallSearchHistory(
      id: json['id'] as String,
      query: json['query'] as String,
      answer: json['answer'] as String? ?? '',
      sources: sources,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  RecallSearchResult toSearchResult() {
    return RecallSearchResult(answer: answer, sources: sources);
  }
}
