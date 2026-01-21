import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/recall_models.dart';

class RecallService {
  static final RecallService _instance = RecallService._internal();
  factory RecallService() => _instance;
  RecallService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> generateEmbeddingForHighlight({
    required String userId,
    required String bookId,
    required String highlightId,
    required String text,
    int? pageNumber,
  }) async {
    try {
      await _supabase.functions.invoke(
        'generate-embedding',
        body: {
          'userId': userId,
          'bookId': bookId,
          'contentType': 'highlight',
          'contentText': text,
          'pageNumber': pageNumber,
          'sourceId': highlightId,
        },
      );
      debugPrint('Embedding generated for highlight: $highlightId');
    } catch (e) {
      debugPrint('Failed to generate embedding for highlight: $e');
    }
  }

  Future<void> generateEmbeddingForNote({
    required String userId,
    required String bookId,
    required String noteId,
    required String content,
    int? pageNumber,
  }) async {
    try {
      await _supabase.functions.invoke(
        'generate-embedding',
        body: {
          'userId': userId,
          'bookId': bookId,
          'contentType': 'note',
          'contentText': content,
          'pageNumber': pageNumber,
          'sourceId': noteId,
        },
      );
      debugPrint('Embedding generated for note: $noteId');
    } catch (e) {
      debugPrint('Failed to generate embedding for note: $e');
    }
  }

  Future<void> generateEmbeddingForPhotoOcr({
    required String userId,
    required String bookId,
    required String photoId,
    required String ocrText,
    int? pageNumber,
  }) async {
    try {
      await _supabase.functions.invoke(
        'generate-embedding',
        body: {
          'userId': userId,
          'bookId': bookId,
          'contentType': 'photo_ocr',
          'contentText': ocrText,
          'pageNumber': pageNumber,
          'sourceId': photoId,
        },
      );
      debugPrint('Embedding generated for photo OCR: $photoId');
    } catch (e) {
      debugPrint('Failed to generate embedding for photo OCR: $e');
    }
  }

  Future<RecallSearchResult?> search({
    required String bookId,
    required String query,
  }) async {
    try {
      debugPrint('🔍 Recall search: bookId=$bookId, query=$query');
      final response = await _supabase.functions.invoke(
        'recall-search',
        body: {
          'bookId': bookId,
          'query': query,
        },
      );

      debugPrint('🔍 Recall search response: status=${response.status}');
      debugPrint('🔍 Recall search response data: ${response.data}');

      if (response.status != 200) {
        debugPrint(
            '🔴 Recall search failed: ${response.status} - ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return RecallSearchResult.fromJson(data);
    } catch (e, stackTrace) {
      debugPrint('🔴 Recall search error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      return null;
    }
  }
}
