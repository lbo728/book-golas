import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

class GoogleVisionOcrService {
  static final GoogleVisionOcrService _instance =
      GoogleVisionOcrService._internal();
  factory GoogleVisionOcrService() => _instance;
  GoogleVisionOcrService._internal();

  static const String _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  Future<String?> extractTextFromImageUrl(String imageUrl) async {
    if (!AppConfig.hasGoogleCloudVisionApiKey) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return null;
      }

      return await extractTextFromBytes(response.bodyBytes);
    } catch (e) {
      return null;
    }
  }

  Future<String?> extractTextFromBytes(Uint8List imageBytes) async {
    if (!AppConfig.hasGoogleCloudVisionApiKey) {
      return null;
    }

    try {
      final base64Image = base64Encode(imageBytes);

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

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${AppConfig.googleCloudVisionApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = jsonResponse['responses'] as List<dynamic>?;

      if (responses == null || responses.isEmpty) {
        return null;
      }

      final firstResponse = responses[0] as Map<String, dynamic>;
      final textAnnotations =
          firstResponse['textAnnotations'] as List<dynamic>?;

      if (textAnnotations == null || textAnnotations.isEmpty) {
        return null;
      }

      final fullText =
          textAnnotations[0]['description'] as String?;

      if (fullText == null || fullText.isEmpty) {
        return null;
      }

      return _cleanupExtractedText(fullText);
    } catch (e) {
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
