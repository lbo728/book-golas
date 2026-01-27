class ReadingRecord {
  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookImageUrl;
  final String contentType;
  final String contentText;
  final int? pageNumber;
  final String? sourceId;
  final DateTime createdAt;

  ReadingRecord({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl,
    required this.contentType,
    required this.contentText,
    this.pageNumber,
    this.sourceId,
    required this.createdAt,
  });

  factory ReadingRecord.fromJson(Map<String, dynamic> json) {
    final books = json['books'] as Map<String, dynamic>?;
    return ReadingRecord(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      bookTitle: books?['title'] as String? ?? '알 수 없는 책',
      bookImageUrl: books?['image_url'] as String?,
      contentType: json['content_type'] as String,
      contentText: json['content_text'] as String,
      pageNumber: json['page_number'] as int?,
      sourceId: json['source_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get typeLabel {
    switch (contentType) {
      case 'highlight':
        return '하이라이트';
      case 'note':
        return '메모';
      case 'photo_ocr':
        return '사진';
      default:
        return contentType;
    }
  }

  String get typeIcon {
    switch (contentType) {
      case 'highlight':
        return '✨';
      case 'note':
        return '📝';
      case 'photo_ocr':
        return '📷';
      default:
        return '📄';
    }
  }
}

class GroupedRecords {
  final String bookId;
  final String bookTitle;
  final String? bookImageUrl;
  final List<ReadingRecord> records;

  GroupedRecords({
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl,
    required this.records,
  });

  int get highlightCount =>
      records.where((r) => r.contentType == 'highlight').length;
  int get noteCount => records.where((r) => r.contentType == 'note').length;
  int get photoCount =>
      records.where((r) => r.contentType == 'photo_ocr').length;
}
