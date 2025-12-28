class ReadingProgressRecord {
  final String? id;
  final String userId;
  final String bookId;
  final int page;
  final int previousPage;
  final DateTime createdAt;

  ReadingProgressRecord({
    this.id,
    required this.userId,
    required this.bookId,
    required this.page,
    this.previousPage = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get pagesRead => page - previousPage;

  factory ReadingProgressRecord.fromJson(Map<String, dynamic> json) {
    return ReadingProgressRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      page: json['page'] as int,
      previousPage: json['previous_page'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'book_id': bookId,
      'page': page,
      'previous_page': previousPage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ReadingProgressRecord(bookId: $bookId, page: $page, pagesRead: $pagesRead, createdAt: $createdAt)';
  }
}
