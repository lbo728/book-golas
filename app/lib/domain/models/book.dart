/// 독서 상태를 나타내는 enum
enum BookStatus {
  planned('planned'),   // 읽을 예정
  reading('reading'),   // 독서 중
  completed('completed'); // 완독

  final String value;
  const BookStatus(this.value);

  static BookStatus fromString(String? s) =>
      values.firstWhere((e) => e.value == s, orElse: () => reading);
}

class BookSearchResult {
  final String title;
  final String author;
  final String? imageUrl;
  final int? totalPages;
  final String? isbn;

  BookSearchResult({
    required this.title,
    required this.author,
    this.imageUrl,
    this.totalPages,
    this.isbn,
  });

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    int? parsedPages;
    final itemPage = json['subInfo']?['itemPage'];

    if (itemPage != null) {
      if (itemPage is int) {
        parsedPages = itemPage;
      } else if (itemPage is String) {
        parsedPages = int.tryParse(itemPage);
      } else {
        parsedPages = int.tryParse(itemPage.toString());
      }
    }

    print('📖 책 파싱 완료 - 제목: ${json['title']}, 페이지: $parsedPages');

    return BookSearchResult(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      imageUrl: json['cover'],
      totalPages: parsedPages,
      isbn: json['isbn'],
    );
  }
}

class Book {
  final String? id;
  final String title;
  final String? author;
  final DateTime startDate;
  final DateTime targetDate;
  final String? imageUrl;
  final int currentPage;
  final int totalPages;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final int attemptCount;
  final int? dailyTargetPages;

  Book({
    this.id,
    required this.title,
    this.author,
    required this.startDate,
    required this.targetDate,
    this.imageUrl,
    this.currentPage = 0,
    this.totalPages = 0,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.attemptCount = 1,
    this.dailyTargetPages,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    DateTime? startDate,
    DateTime? targetDate,
    String? imageUrl,
    int? currentPage,
    int? totalPages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    int? attemptCount,
    int? dailyTargetPages,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      imageUrl: imageUrl ?? this.imageUrl,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      dailyTargetPages: dailyTargetPages ?? this.dailyTargetPages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate.toIso8601String(),
      'image_url': imageUrl,
      'current_page': currentPage,
      'total_pages': totalPages,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (status != null) 'status': status,
      'attempt_count': attemptCount,
      if (dailyTargetPages != null) 'daily_target_pages': dailyTargetPages,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String?,
      title: json['title'] as String,
      author: json['author'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      targetDate: DateTime.parse(json['target_date'] as String),
      imageUrl: json['image_url'] as String?,
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      status: json['status'] as String?,
      attemptCount: json['attempt_count'] as int? ?? 1,
      dailyTargetPages: json['daily_target_pages'] as int?,
    );
  }
}
