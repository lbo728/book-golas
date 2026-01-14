class IsbnValidator {
  static bool isValidISBN13(String isbn) {
    final cleaned = cleanISBN(isbn);

    if (cleaned.length != 13) return false;
    if (!RegExp(r'^\d{13}$').hasMatch(cleaned)) return false;
    if (!cleaned.startsWith('978') && !cleaned.startsWith('979')) return false;

    return validateChecksum(cleaned);
  }

  static String cleanISBN(String isbn) {
    return isbn.replaceAll(RegExp(r'[\s-]'), '');
  }

  static bool validateChecksum(String isbn13) {
    if (isbn13.length != 13) return false;

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.tryParse(isbn13[i]);
      if (digit == null) return false;
      sum += digit * (i % 2 == 0 ? 1 : 3);
    }

    final checkDigit = (10 - (sum % 10)) % 10;
    final lastDigit = int.tryParse(isbn13[12]);

    return lastDigit == checkDigit;
  }
}
