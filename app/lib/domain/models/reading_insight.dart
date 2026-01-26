class ReadingInsight {
  final String id;
  final String title;
  final String description;
  final String category; // "pattern", "milestone", "reflection"
  final List<String> relatedBooks;
  final DateTime generatedAt;

  ReadingInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.relatedBooks,
    required this.generatedAt,
  });

  factory ReadingInsight.fromJson(Map<String, dynamic> json) {
    return ReadingInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      relatedBooks: (json['relatedBooks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'relatedBooks': relatedBooks,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  ReadingInsight copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? relatedBooks,
    DateTime? generatedAt,
  }) {
    return ReadingInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      relatedBooks: relatedBooks ?? this.relatedBooks,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
