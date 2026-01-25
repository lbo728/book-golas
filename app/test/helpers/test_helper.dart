import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test data factory for common test scenarios
class TestData {
  /// Sample book JSON data for testing
  static Map<String, dynamic> get sampleBookJson => {
        'id': 'test-book-id',
        'title': 'Test Book',
        'author': 'Test Author',
        'current_page': 50,
        'total_pages': 200,
        'status': 'reading',
        'user_id': 'test-user-id',
        'start_date': DateTime.now().toIso8601String(),
        'target_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Sample book list for testing
  static List<Map<String, dynamic>> get sampleBookList => [
        sampleBookJson,
        {
          'id': 'test-book-id-2',
          'title': 'Another Test Book',
          'author': 'Another Author',
          'current_page': 100,
          'total_pages': 300,
          'status': 'completed',
          'user_id': 'test-user-id',
          'start_date': DateTime.now()
              .subtract(const Duration(days: 60))
              .toIso8601String(),
          'target_date': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'created_at': DateTime.now()
              .subtract(const Duration(days: 60))
              .toIso8601String(),
          'updated_at': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
        },
      ];

  /// Sample user JSON data for testing
  static Map<String, dynamic> get sampleUserJson => {
        'id': 'test-user-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Sample reading goal JSON data for testing
  static Map<String, dynamic> get sampleGoalJson => {
        'id': 'test-goal-id',
        'user_id': 'test-user-id',
        'target_books': 12,
        'target_pages': 3000,
        'year': DateTime.now().year,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
}

/// Test utilities for common operations
class TestUtils {
  /// Create a book JSON with custom values
  static Map<String, dynamic> createBookJson({
    String id = 'test-book-id',
    String title = 'Test Book',
    String author = 'Test Author',
    int currentPage = 50,
    int totalPages = 200,
    String status = 'reading',
    String userId = 'test-user-id',
  }) {
    return {
      'id': id,
      'title': title,
      'author': author,
      'current_page': currentPage,
      'total_pages': totalPages,
      'status': status,
      'user_id': userId,
      'start_date': DateTime.now().toIso8601String(),
      'target_date':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a user JSON with custom values
  static Map<String, dynamic> createUserJson({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String name = 'Test User',
    String? avatarUrl,
  }) {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a goal JSON with custom values
  static Map<String, dynamic> createGoalJson({
    String id = 'test-goal-id',
    String userId = 'test-user-id',
    int targetBooks = 12,
    int targetPages = 3000,
    int? year,
  }) {
    return {
      'id': id,
      'user_id': userId,
      'target_books': targetBooks,
      'target_pages': targetPages,
      'year': year ?? DateTime.now().year,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension methods for test assertions
extension TestAssertions on WidgetTester {
  /// Find a widget by type and verify it exists
  Future<void> expectWidgetExists<T extends Widget>() async {
    expect(find.byType(T), findsOneWidget);
  }

  /// Find a widget by type and verify it doesn't exist
  Future<void> expectWidgetNotExists<T extends Widget>() async {
    expect(find.byType(T), findsNothing);
  }

  /// Find text and verify it exists
  Future<void> expectTextExists(String text) async {
    expect(find.text(text), findsOneWidget);
  }

  /// Find text and verify it doesn't exist
  Future<void> expectTextNotExists(String text) async {
    expect(find.text(text), findsNothing);
  }
}
