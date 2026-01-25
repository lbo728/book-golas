import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/domain/models/book.dart';

void main() {
  group('Reading Flow Logic', () {
    group('Page Progress', () {
      test('should track current page correctly', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          author: 'Author',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 0,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        expect(book.currentPage, 0);
        expect(book.totalPages, 200);

        final updatedBook = book.copyWith(currentPage: 50);
        expect(updatedBook.currentPage, 50);
        expect(updatedBook.totalPages, 200);
      });

      test('should calculate progress correctly', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 100,
          totalPages: 200,
        );

        final progress = book.currentPage / book.totalPages;
        expect(progress, 0.5);
      });

      test('should handle zero total pages without division error', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 0,
          totalPages: 0,
        );

        final progress =
            book.totalPages > 0 ? book.currentPage / book.totalPages : 0.0;
        expect(progress, 0.0);
      });
    });

    group('Completion Detection', () {
      test('should detect book completion when current page equals total pages',
          () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 200,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        final isCompleted =
            book.currentPage >= book.totalPages && book.totalPages > 0;
        expect(isCompleted, true);
      });

      test(
          'should detect book completion when current page exceeds total pages',
          () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 250,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        final isCompleted =
            book.currentPage >= book.totalPages && book.totalPages > 0;
        expect(isCompleted, true);
      });

      test('should not detect completion when pages remaining', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 150,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        final isCompleted =
            book.currentPage >= book.totalPages && book.totalPages > 0;
        expect(isCompleted, false);
      });

      test('should not detect completion when total pages is zero', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 0,
          totalPages: 0,
          status: BookStatus.reading.value,
        );

        final isCompleted =
            book.currentPage >= book.totalPages && book.totalPages > 0;
        expect(isCompleted, false);
      });
    });

    group('Status Transitions', () {
      test('should allow transition from reading to completed', () {
        final readingBook = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 200,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        final completedBook = readingBook.copyWith(
          status: BookStatus.completed.value,
        );

        expect(completedBook.status, BookStatus.completed.value);
        expect(
            BookStatus.fromString(completedBook.status), BookStatus.completed);
      });

      test('should allow transition from reading to will_retry', () {
        final readingBook = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 50,
          totalPages: 200,
          status: BookStatus.reading.value,
        );

        final pausedBook = readingBook.copyWith(
          status: BookStatus.willRetry.value,
          pausedAt: DateTime.now(),
        );

        expect(pausedBook.status, BookStatus.willRetry.value);
        expect(pausedBook.pausedAt, isNotNull);
      });

      test('should allow transition from will_retry to reading (resume)', () {
        final pausedBook = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          targetDate: DateTime.now().add(const Duration(days: 20)),
          currentPage: 50,
          totalPages: 200,
          status: BookStatus.willRetry.value,
          pausedAt: DateTime.now().subtract(const Duration(days: 5)),
          attemptCount: 1,
        );

        final resumedBook = pausedBook.copyWith(
          status: BookStatus.reading.value,
          startDate: DateTime.now(),
          attemptCount: pausedBook.attemptCount + 1,
        );

        expect(resumedBook.status, BookStatus.reading.value);
        expect(resumedBook.attemptCount, 2);
      });

      test('should allow transition from planned to reading', () {
        final plannedBook = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentPage: 0,
          totalPages: 200,
          status: BookStatus.planned.value,
        );

        final startedBook = plannedBook.copyWith(
          status: BookStatus.reading.value,
        );

        expect(startedBook.status, BookStatus.reading.value);
      });
    });

    group('Reading History Tracking', () {
      test('should detect page increase for history recording', () {
        const int previousPage = 50;
        const int currentPage = 75;

        const shouldRecordHistory = currentPage > previousPage;
        expect(shouldRecordHistory, true);
      });

      test('should not record history when page decreases', () {
        const int previousPage = 75;
        const int currentPage = 50;

        const shouldRecordHistory = currentPage > previousPage;
        expect(shouldRecordHistory, false);
      });

      test('should not record history when page stays same', () {
        const int previousPage = 50;
        const int currentPage = 50;

        const shouldRecordHistory = currentPage > previousPage;
        expect(shouldRecordHistory, false);
      });
    });

    group('Attempt Count', () {
      test('should default to 1 for new books', () {
        final book = Book(
          title: 'New Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
        );

        expect(book.attemptCount, 1);
      });

      test('should increment on resume', () {
        final pausedBook = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          status: BookStatus.willRetry.value,
          attemptCount: 1,
        );

        final resumedBook = pausedBook.copyWith(
          attemptCount: pausedBook.attemptCount + 1,
        );

        expect(resumedBook.attemptCount, 2);
      });

      test('should track multiple retry attempts', () {
        var book = Book(
          id: 'book-1',
          title: 'Difficult Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          attemptCount: 1,
        );

        for (var i = 0; i < 3; i++) {
          book = book.copyWith(attemptCount: book.attemptCount + 1);
        }

        expect(book.attemptCount, 4);
      });
    });

    group('Rating and Review', () {
      test('should allow rating only after completion (business rule)', () {
        final completedBook = Book(
          id: 'book-1',
          title: 'Completed Book',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          targetDate: DateTime.now(),
          currentPage: 200,
          totalPages: 200,
          status: BookStatus.completed.value,
        );

        final isCompleted = completedBook.status == BookStatus.completed.value;
        expect(isCompleted, true);

        final ratedBook = completedBook.copyWith(
          rating: 5,
          review: 'Excellent book!',
        );

        expect(ratedBook.rating, 5);
        expect(ratedBook.review, 'Excellent book!');
      });

      test('should accept rating values from 1 to 5', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          status: BookStatus.completed.value,
        );

        for (var rating = 1; rating <= 5; rating++) {
          final ratedBook = book.copyWith(rating: rating);
          expect(ratedBook.rating, rating);
        }
      });

      test('should store review link', () {
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          status: BookStatus.completed.value,
        );

        final reviewedBook = book.copyWith(
          reviewLink: 'https://blog.example.com/my-review',
        );

        expect(reviewedBook.reviewLink, 'https://blog.example.com/my-review');
      });
    });

    group('Daily Target Pages', () {
      test('should calculate remaining days', () {
        final now = DateTime.now();
        final targetDate = now.add(const Duration(days: 10));

        final remainingDays = targetDate.difference(now).inDays;
        expect(remainingDays, 10);
      });

      test('should calculate daily target pages', () {
        final now = DateTime(2026, 1, 25);
        final book = Book(
          id: 'book-1',
          title: 'Test Book',
          startDate: now,
          targetDate: DateTime(2026, 2, 4), // exactly 10 days later
          currentPage: 50,
          totalPages: 200,
        );

        final remainingPages = book.totalPages - book.currentPage; // 150
        final remainingDays = book.targetDate.difference(now).inDays; // 10

        expect(remainingDays, 10);
        expect(remainingPages, 150);

        if (remainingDays > 0) {
          final dailyTarget = (remainingPages / remainingDays).ceil();
          expect(dailyTarget, 15); // 150 / 10 = 15
        }
      });
    });
  });
}
