import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIContentService {
  static final AIContentService _instance = AIContentService._internal();
  factory AIContentService() => _instance;
  AIContentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> generateBookReviewDraft({
    required String bookId,
  }) async {
    try {
      debugPrint(
          '[AIContentService] Generating review draft for book: $bookId');

      final response = await _supabase.functions.invoke(
        'generate-book-review',
        body: {
          'bookId': bookId,
        },
      );

      if (response.status != 200) {
        debugPrint('[AIContentService] Error status: ${response.status}');
        final errorData = response.data;
        final errorMessage =
            errorData is Map ? errorData['error'] : 'Unknown error';
        throw Exception(errorMessage);
      }

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['error'] ?? 'Failed to generate review');
      }

      final draft = data['draft'] as String?;
      final memosUsed = data['memosUsed'] as int? ?? 0;

      debugPrint(
          '[AIContentService] Review draft generated successfully, memos used: $memosUsed');

      return draft;
    } on FunctionException catch (e) {
      debugPrint('[AIContentService] FunctionException: ${e.details}');
      return null;
    } catch (e) {
      debugPrint('[AIContentService] Failed to generate review draft: $e');
      return null;
    }
  }
}
