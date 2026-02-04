class DailyReadingData {
  final DateTime date;
  final List<BookReadingInfo> books;

  DailyReadingData({
    required this.date,
    required this.books,
  });

  int get bookCount => books.length;

  BookReadingInfo? get representativeBook =>
      books.isNotEmpty ? books.first : null;

  bool get hasCompletedBook => books.any((book) => book.isCompletedOnThisDay);

  bool get isRepresentativeBookCompleted =>
      representativeBook?.isCompletedOnThisDay ?? false;
}

class BookReadingInfo {
  final String bookId;
  final String title;
  final String? author;
  final String? imageUrl;
  final int pagesReadOnThisDay;
  final String bookStatus;
  final DateTime? completedAt;
  final DateTime startDate;
  final DateTime? targetDate;
  final DateTime lastUpdatedAt;

  BookReadingInfo({
    required this.bookId,
    required this.title,
    this.author,
    this.imageUrl,
    required this.pagesReadOnThisDay,
    required this.bookStatus,
    this.completedAt,
    required this.startDate,
    this.targetDate,
    required this.lastUpdatedAt,
  });

  bool get isCompletedOnThisDay {
    if (completedAt == null) return false;
    return _isSameDay(completedAt!, lastUpdatedAt);
  }

  bool get isCompleted => bookStatus == 'completed';

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  factory BookReadingInfo.fromJson(Map<String, dynamic> json, DateTime date) {
    final book = json['books'] as Map<String, dynamic>;
    final page = json['page'] as int;
    final previousPage = json['previous_page'] as int? ?? 0;

    return BookReadingInfo(
      bookId: json['book_id'] as String,
      title: book['title'] as String,
      author: book['author'] as String?,
      imageUrl: book['image_url'] as String?,
      pagesReadOnThisDay: page - previousPage,
      bookStatus: book['status'] as String? ?? 'reading',
      completedAt: book['status'] == 'completed' && book['updated_at'] != null
          ? DateTime.parse(book['updated_at'] as String)
          : null,
      startDate: DateTime.parse(book['start_date'] as String),
      targetDate: book['target_date'] != null
          ? DateTime.parse(book['target_date'] as String)
          : null,
      lastUpdatedAt: DateTime.parse(json['created_at'] as String),
    );
  }

  BookReadingInfo copyWith({
    String? bookId,
    String? title,
    String? author,
    String? imageUrl,
    int? pagesReadOnThisDay,
    String? bookStatus,
    DateTime? completedAt,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? lastUpdatedAt,
  }) {
    return BookReadingInfo(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      pagesReadOnThisDay: pagesReadOnThisDay ?? this.pagesReadOnThisDay,
      bookStatus: bookStatus ?? this.bookStatus,
      completedAt: completedAt ?? this.completedAt,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
