import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:book_golas/config/app_config.dart';
import 'package:book_golas/utils/html_utils.dart';

class NaverBooksApiService {
  static const String _baseUrl =
      'https://openapi.naver.com/v1/search/book.json';

  static Future<String?> fetchDescription(String isbn) async {
    return _fetchDescriptionByQuery(isbn);
  }

  static Future<String?> fetchDescriptionByTitle(
      String title, String? author) async {
    final query =
        author != null && author.isNotEmpty ? '$title $author' : title;
    return _fetchDescriptionByQuery(query);
  }

  static Future<String?> _fetchDescriptionByQuery(String query) async {
    debugPrint('📗 [Naver] query="$query"');
    debugPrint(
        '📗 [Naver] clientId=${AppConfig.naverClientId.isNotEmpty ? "${AppConfig.naverClientId.substring(0, 4)}..." : "EMPTY"}');
    if (AppConfig.naverClientId.isEmpty ||
        AppConfig.naverClientSecret.isEmpty) {
      debugPrint('📗 [Naver] API 키 없음 → null 반환');
      return null;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query': query,
      });
      debugPrint('📗 [Naver] URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'X-Naver-Client-Id': AppConfig.naverClientId,
          'X-Naver-Client-Secret': AppConfig.naverClientSecret,
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('📗 [Naver] status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        debugPrint(
            '📗 [Naver] total=${data['total']}, items=${items?.length ?? 0}');

        if (items != null && items.isNotEmpty) {
          final description = items[0]['description'] as String?;
          debugPrint(
              '📗 [Naver] desc=${description != null ? "${description.length}자" : "null"}');
          if (description != null && description.isNotEmpty) {
            return stripAndDecodeHtml(description);
          }
        }
      } else {
        debugPrint(
            '📗 [Naver] ERROR status=${response.statusCode}, body=${response.body.substring(0, 200)}');
      }

      return null;
    } catch (e) {
      debugPrint('📗 [Naver] EXCEPTION: $e');
      return null;
    }
  }
}
