class ReadingGoal {
  final String? id;
  final String userId;
  final int year;
  final int targetBooks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReadingGoal({
    this.id,
    required this.userId,
    required this.year,
    required this.targetBooks,
    this.createdAt,
    this.updatedAt,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      year: json['year'] as int,
      targetBooks: json['target_books'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'year': year,
      'target_books': targetBooks,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ReadingGoal copyWith({
    String? id,
    String? userId,
    int? year,
    int? targetBooks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
