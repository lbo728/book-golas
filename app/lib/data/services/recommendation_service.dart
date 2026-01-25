import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookRecommendation {
  final String title;
  final String author;
  final String reason;
  String? imageUrl;

  BookRecommendation({
    required this.title,
    required this.author,
    required this.reason,
    this.imageUrl,
  });

  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      title: json['title'] as String,
      author: json['author'] as String,
      reason: json['reason'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  BookRecommendation copyWith({String? imageUrl}) {
    return BookRecommendation(
      title: title,
      author: author,
      reason: reason,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class RecommendationStats {
  final int totalBooksCompleted;
  final double averageRating;
  final List<String> favoriteGenres;
  final int averageCompletionDays;
  final int booksAnalyzed;

  RecommendationStats({
    required this.totalBooksCompleted,
    required this.averageRating,
    required this.favoriteGenres,
    required this.averageCompletionDays,
    required this.booksAnalyzed,
  });

  factory RecommendationStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final genres = stats['favoriteGenres'] as List<dynamic>? ?? [];

    return RecommendationStats(
      totalBooksCompleted: stats['totalBooksCompleted'] as int? ?? 0,
      averageRating: (stats['averageRating'] as num?)?.toDouble() ?? 0.0,
      favoriteGenres: genres
          .map((g) => (g as Map<String, dynamic>)['genre'] as String)
          .toList(),
      averageCompletionDays: stats['averageCompletionDays'] as int? ?? 0,
      booksAnalyzed: json['booksAnalyzed'] as int? ?? 0,
    );
  }
}

class RecommendationResult {
  final bool success;
  final List<BookRecommendation> recommendations;
  final RecommendationStats? stats;
  final String? error;

  RecommendationResult({
    required this.success,
    required this.recommendations,
    this.stats,
    this.error,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final recommendationsJson = json['recommendations'] as List<dynamic>? ?? [];
    final profileJson = json['profile'] as Map<String, dynamic>?;

    return RecommendationResult(
      success: success,
      recommendations: recommendationsJson
          .map((r) => BookRecommendation.fromJson(r as Map<String, dynamic>))
          .toList(),
      stats: profileJson != null
          ? RecommendationStats.fromJson(profileJson)
          : null,
      error: json['error'] as String?,
    );
  }
}

class RecommendationService {
  final _supabase = Supabase.instance.client;

  Future<int> getCompletedBooksCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('books')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'completed');

      return (response as List).length;
    } catch (e) {
      debugPrint('[RecommendationService] getCompletedBooksCount error: $e');
      return 0;
    }
  }

  Future<RecommendationResult> getRecommendations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return RecommendationResult(
          success: false,
          recommendations: [],
          error: 'User not authenticated',
        );
      }

      debugPrint(
          '[RecommendationService] Fetching recommendations for $userId');

      final response = await _supabase.functions.invoke(
        'recommend-next-books',
        body: {'userId': userId},
      );

      debugPrint('[RecommendationService] Response status: ${response.status}');

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        return RecommendationResult(
          success: false,
          recommendations: [],
          error: errorData?['error'] as String? ?? 'Unknown error',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return RecommendationResult.fromJson(data);
    } catch (e) {
      debugPrint('[RecommendationService] Error: $e');
      return RecommendationResult(
        success: false,
        recommendations: [],
        error: e.toString(),
      );
    }
  }

  Future<RecommendationResult?> getCachedRecommendations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('book_recommendations')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final recommendationsJson =
          response['recommendations'] as List<dynamic>? ?? [];
      final profileJson = response['profile_summary'] as Map<String, dynamic>?;

      return RecommendationResult(
        success: true,
        recommendations: recommendationsJson
            .map((r) => BookRecommendation.fromJson(r as Map<String, dynamic>))
            .toList(),
        stats: profileJson != null
            ? RecommendationStats.fromJson(profileJson)
            : null,
      );
    } catch (e) {
      debugPrint('[RecommendationService] Cache error: $e');
      return null;
    }
  }
}
