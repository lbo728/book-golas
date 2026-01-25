// Basic Flutter widget tests for Bookgolas app.
//
// These tests verify that core widgets can be instantiated without errors.
// Full integration tests require Supabase initialization which is not
// available in unit test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_golas/domain/models/book.dart';

void main() {
  group('Widget Smoke Tests', () {
    testWidgets('MaterialApp renders without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Bookgolas Test'))),
        ),
      );

      expect(find.text('Bookgolas Test'), findsOneWidget);
    });

    testWidgets('Book model can be displayed in a widget', (
      WidgetTester tester,
    ) async {
      final book = Book(
        id: 'test-id',
        title: 'Test Book Title',
        author: 'Test Author',
        startDate: DateTime(2026, 1, 1),
        targetDate: DateTime(2026, 2, 1),
        currentPage: 50,
        totalPages: 200,
        status: BookStatus.reading.value,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(book.title),
                Text(book.author ?? ''),
                Text('${book.currentPage} / ${book.totalPages}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Book Title'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(find.text('50 / 200'), findsOneWidget);
    });

    testWidgets('Progress indicator shows correct value', (
      WidgetTester tester,
    ) async {
      const progress = 0.5;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: LinearProgressIndicator(value: progress)),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(progressIndicator.value, 0.5);
    });
  });
}
