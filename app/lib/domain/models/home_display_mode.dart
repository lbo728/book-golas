enum HomeDisplayMode {
  allBooks('all_books'),
  readingDetail('reading_detail');

  final String value;
  const HomeDisplayMode(this.value);

  static HomeDisplayMode fromString(String? s) => values.firstWhere(
        (e) => e.value == s,
        orElse: () => allBooks,
      );

  String toDisplayString() {
    switch (this) {
      case HomeDisplayMode.allBooks:
        return '모든 독서만 보기';
      case HomeDisplayMode.readingDetail:
        return '진행 중인 독서만 보기';
    }
  }
}
