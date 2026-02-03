class ReadingSession {
  final String? id;
  final String userId;
  final String bookId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final DateTime? createdAt;

  ReadingSession({
    this.id,
    required this.userId,
    required this.bookId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.createdAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'book_id': bookId,
      'started_at': startedAt.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      'duration_seconds': durationSeconds,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ReadingSession copyWith({
    String? id,
    String? userId,
    String? bookId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ReadingSession(id: $id, bookId: $bookId, userId: $userId, startedAt: $startedAt, endedAt: $endedAt, duration: $duration)';
  }
}
