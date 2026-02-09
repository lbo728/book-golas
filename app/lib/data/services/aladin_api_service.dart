import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:book_golas/config/app_config.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/core/utils/isbn_validator.dart';
import 'package:book_golas/utils/html_utils.dart';

class AladinApiService {
  static Future<List<BookSearchResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    AppConfig.validateApiKeys();

    try {
      final cleanedQuery = IsbnValidator.cleanISBN(query);
      if (IsbnValidator.isValidISBN13(cleanedQuery)) {
        final result = await lookupByISBN(cleanedQuery);
        return result != null ? [result] : [];
      }

      final searchUri = Uri.parse(AppConfig.aladinBaseUrl).replace(
        queryParameters: {
          'ttbkey': AppConfig.aladinApiKey,
          'Query': query,
          'QueryType': 'Title',
          'MaxResults': AppConfig.maxSearchResults.toString(),
          'start': '1',
          'SearchTarget': 'Book',
          'output': 'js',
          'Version': AppConfig.apiVersion,
          'Cover': 'Big',
        },
      );

      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final List<dynamic> searchItems = searchData['item'] ?? [];

        List<BookSearchResult> detailedBooks = [];

        for (var item in searchItems.take(5)) {
          final isbn13 = item['isbn13'];
          if (isbn13 != null && isbn13.toString().isNotEmpty) {
            final detailedBook = await lookupByISBN(isbn13.toString());
            if (detailedBook != null) {
              detailedBooks.add(detailedBook);
            } else {
              detailedBooks.add(BookSearchResult.fromJson(item));
            }
          } else {
            detailedBooks.add(BookSearchResult.fromJson(item));
          }
        }

        return detailedBooks;
      } else {
        throw Exception('Failed to load books: ${searchResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }

  static Future<BookSearchResult?> lookupByISBN(String isbn) async {
    try {
      final lookupUri =
          Uri.parse('http://www.aladin.co.kr/ttb/api/ItemLookUp.aspx').replace(
            queryParameters: {
              'ttbkey': AppConfig.aladinApiKey,
              'itemIdType': 'ISBN13',
              'ItemId': isbn,
              'output': 'js',
              'Version': AppConfig.apiVersion,
              'OptResult': 'ebookList,usedList,reviewList',
              'Cover': 'Big',
            },
          );

      final response = await http.get(lookupUri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final List<dynamic> items = jsonData['item'] ?? [];
        if (items.isNotEmpty) {
          return BookSearchResult.fromJson(items[0]);
        }
      }
    } catch (e) {
      // 에러 발생 시 null 반환
    }
    return null;
  }

  static Future<String?> fetchDescriptionByTitle(String title) async {
    debugPrint('📕 [Aladin] fetchDescriptionByTitle title="$title"');
    try {
      final uri = Uri.parse(AppConfig.aladinBaseUrl).replace(
        queryParameters: {
          'ttbkey': AppConfig.aladinApiKey,
          'Query': title,
          'QueryType': 'Title',
          'MaxResults': '1',
          'start': '1',
          'SearchTarget': 'Book',
          'output': 'js',
          'Version': AppConfig.apiVersion,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      debugPrint('📕 [Aladin] title search status=${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> items = jsonData['item'] ?? [];
        debugPrint('📕 [Aladin] title search items=${items.length}');
        if (items.isNotEmpty) {
          final description = items[0]['description'] as String?;
          debugPrint(
            '📕 [Aladin] title search desc=${description != null ? "${description.length}자" : "null"}',
          );
          if (description != null && description.isNotEmpty) {
            return stripAndDecodeHtml(description);
          }
        }
      }
    } catch (e) {
      debugPrint('📕 [Aladin] title search ERROR: $e');
    }
    return null;
  }

  static Future<String?> fetchDescription(String isbn13) async {
    debugPrint('📕 [Aladin] fetchDescription isbn=$isbn13');
    try {
      final uri = Uri.parse('http://www.aladin.co.kr/ttb/api/ItemLookUp.aspx')
          .replace(
            queryParameters: {
              'ttbkey': AppConfig.aladinApiKey,
              'itemIdType': 'ISBN13',
              'ItemId': isbn13,
              'output': 'js',
              'Version': AppConfig.apiVersion,
            },
          );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      debugPrint('📕 [Aladin] status=${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> items = jsonData['item'] ?? [];
        debugPrint('📕 [Aladin] items=${items.length}');
        if (items.isNotEmpty) {
          final description = items[0]['description'] as String?;
          debugPrint(
            '📕 [Aladin] desc=${description != null ? "${description.length}자" : "null"}',
          );
          if (description != null && description.isNotEmpty) {
            return stripAndDecodeHtml(description);
          }
        }
      }
    } catch (e) {
      debugPrint('📕 [Aladin] ERROR: $e');
    }
    return null;
  }
}
