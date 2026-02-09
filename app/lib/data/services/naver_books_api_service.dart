import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:book_golas/config/app_config.dart';
import 'package:book_golas/utils/html_utils.dart';

class NaverBooksApiService {
  static const String _baseUrl =
      'https://openapi.naver.com/v1/search/book.json';

  static Future<String?> fetchDescription(String isbn) async {
    if (AppConfig.naverClientId.isEmpty ||
        AppConfig.naverClientSecret.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query': isbn,
      });

      final response = await http.get(
        uri,
        headers: {
          'X-Naver-Client-Id': AppConfig.naverClientId,
          'X-Naver-Client-Secret': AppConfig.naverClientSecret,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final description = items[0]['description'] as String?;
          if (description != null && description.isNotEmpty) {
            return stripAndDecodeHtml(description);
          }
        }
      } else {
        debugPrint('Naver Books API error: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching Naver description: $e');
      return null;
    }
  }
}
