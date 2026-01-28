import 'dart:ui';

import 'package:book_golas/data/services/aladin_api_service.dart';
import 'package:book_golas/data/services/google_books_api_service.dart';
import 'package:book_golas/domain/models/book.dart';

/// Locale-aware book search service
///
/// Automatically selects the appropriate API based on the current locale:
/// - Korean (ko): Aladin API (Korean books)
/// - English (en): Google Books API (International books)
class BookSearchService {
  /// Search books using locale-appropriate API
  static Future<List<BookSearchResult>> searchBooks(
    String query,
    Locale locale,
  ) async {
    if (locale.languageCode == 'ko') {
      return AladinApiService.searchBooks(query);
    } else {
      return GoogleBooksApiService.searchBooks(query);
    }
  }

  /// Lookup book by ISBN using locale-appropriate API
  static Future<BookSearchResult?> lookupByISBN(
    String isbn,
    Locale locale,
  ) async {
    if (locale.languageCode == 'ko') {
      return AladinApiService.lookupByISBN(isbn);
    } else {
      return GoogleBooksApiService.lookupByISBN(isbn);
    }
  }
}
