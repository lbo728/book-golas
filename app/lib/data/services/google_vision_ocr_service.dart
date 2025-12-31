import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:book_golas/config/app_config.dart';

class GoogleVisionOcrService {
  static final GoogleVisionOcrService _instance =
      GoogleVisionOcrService._internal();
  factory GoogleVisionOcrService() => _instance;
  GoogleVisionOcrService._internal();

  static const String _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  Future<String?> extractTextFromImageUrl(String imageUrl) async {
    if (!AppConfig.hasGoogleCloudVisionApiKey) {
      debugPrint('🔴 OCR: API 키가 설정되지 않았습니다.');
      return null;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        debugPrint('🔴 OCR: 이미지 다운로드 실패 - ${response.statusCode}');
        return null;
      }

      return await extractTextFromBytes(response.bodyBytes);
    } catch (e) {
      debugPrint('🔴 OCR: 이미지 다운로드 에러 - $e');
      return null;
    }
  }

  Future<String?> extractTextFromBytes(Uint8List imageBytes) async {
    if (!AppConfig.hasGoogleCloudVisionApiKey) {
      debugPrint('🔴 OCR: API 키가 설정되지 않았습니다.');
      return null;
    }

    debugPrint('🟡 OCR: 텍스트 추출 시작 (이미지 크기: ${imageBytes.length} bytes)');

    try {
      final base64Image = base64Encode(imageBytes);
      debugPrint('🟡 OCR: Base64 인코딩 완료 (길이: ${base64Image.length})');

      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              },
            ],
            'imageContext': {
              'languageHints': ['ko', 'en'],
            },
          },
        ],
      };

      debugPrint('🟡 OCR: API 호출 중...');
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${AppConfig.googleCloudVisionApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('🟡 OCR: API 응답 코드 - ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('🔴 OCR: API 에러 - ${response.body}');
        return null;
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = jsonResponse['responses'] as List<dynamic>?;

      if (responses == null || responses.isEmpty) {
        debugPrint('🔴 OCR: 응답이 비어있습니다.');
        return null;
      }

      final firstResponse = responses[0] as Map<String, dynamic>;

      // 에러 체크
      if (firstResponse.containsKey('error')) {
        debugPrint('🔴 OCR: API 에러 - ${firstResponse['error']}');
        return null;
      }

      final textAnnotations =
          firstResponse['textAnnotations'] as List<dynamic>?;

      if (textAnnotations == null || textAnnotations.isEmpty) {
        debugPrint('🟠 OCR: 텍스트가 감지되지 않았습니다.');
        return null;
      }

      final fullText =
          textAnnotations[0]['description'] as String?;

      if (fullText == null || fullText.isEmpty) {
        debugPrint('🟠 OCR: 추출된 텍스트가 비어있습니다.');
        return null;
      }

      debugPrint('🟢 OCR: 텍스트 추출 성공 (길이: ${fullText.length})');
      return _cleanupExtractedText(fullText);
    } catch (e) {
      debugPrint('🔴 OCR: 예외 발생 - $e');
      return null;
    }
  }

  String _cleanupExtractedText(String rawText) {
    String cleaned = rawText.trim();

    cleaned = cleaned
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    final lines = cleaned.split('\n');
    final cleanedLines = lines.map((line) => line.trim()).toList();
    cleaned = cleanedLines.join('\n');

    return cleaned;
  }

  String getPreviewText(String? fullText, {int maxLines = 2}) {
    if (fullText == null || fullText.isEmpty) {
      return '';
    }

    final lines = fullText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return '';
    }

    if (lines.length <= maxLines) {
      return lines.join('\n');
    }

    return '${lines.take(maxLines).join('\n')}...';
  }
}
