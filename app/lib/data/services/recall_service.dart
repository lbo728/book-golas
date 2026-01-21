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

  Future<List<RecallSearchHistory>> getRecentSearches({
    required String bookId,
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('recall_search_history')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) =>
              RecallSearchHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('🔴 Failed to get recent searches: $e');
      return [];
    }
  }

  Future<bool> deleteSearchHistory(String historyId) async {
    try {
      await _supabase
          .from('recall_search_history')
          .delete()
          .eq('id', historyId);
      return true;
    } catch (e) {
      debugPrint('🔴 Failed to delete search history: $e');
      return false;
    }
  }

  Future<List<String>> getRecentContentSuggestions({
    required String bookId,
    int limit = 5,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('reading_content_embeddings')
          .select('content_text')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((row) {
        final text = row['content_text'] as String;
        return _extractKeyword(text);
      }).toList();
    } catch (e) {
      debugPrint('🔴 Failed to get content suggestions: $e');
      return [];
    }
  }

  String _extractKeyword(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'''[\"\'.,\-:;!?()\[\]{}]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final words = cleaned.split(' ').where((w) => w.length > 1).toList();

    if (words.isEmpty) return text.substring(0, text.length.clamp(0, 10));

    final keyword = words.take(2).join(' ');
    return keyword.length > 15 ? keyword.substring(0, 15) : keyword;
  }

  Future<String?> getImageUrlBySourceId(String sourceId) async {
    try {
      final response = await _supabase
          .from('book_images')
          .select('image_url')
          .eq('id', sourceId)
          .maybeSingle();

      return response?['image_url'] as String?;
    } catch (e) {
      debugPrint('🔴 Failed to get image URL: $e');
      return null;
    }
  }
}
