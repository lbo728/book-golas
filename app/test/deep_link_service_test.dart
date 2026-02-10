import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/data/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.parseUri - search', () {
    test('should parse search URI as search action', () {
      final uri = Uri(scheme: 'bookgolas', pathSegments: ['book', 'search']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNotNull);
      expect(result!.action, DeepLinkAction.search);
      expect(result.bookId, isNull);
    });
  });

  group('DeepLinkService.parseUri - bookDetail', () {
    test('should extract bookId abc-123 from detail URI', () {
      final uri =
          Uri(scheme: 'bookgolas', pathSegments: ['book', 'detail', 'abc-123']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNotNull);
      expect(result!.action, DeepLinkAction.bookDetail);
      expect(result.bookId, 'abc-123');
    });

    test('should parse UUID-style bookId', () {
      final uri = Uri(
        scheme: 'bookgolas',
        pathSegments: [
          'book',
          'detail',
          '550e8400-e29b-41d4-a716-446655440000'
        ],
      );
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNotNull);
      expect(result!.action, DeepLinkAction.bookDetail);
      expect(result.bookId, '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('DeepLinkService.parseUri - bookRecord', () {
    test('should extract bookId abc-123 from record URI', () {
      final uri =
          Uri(scheme: 'bookgolas', pathSegments: ['book', 'record', 'abc-123']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNotNull);
      expect(result!.action, DeepLinkAction.bookRecord);
      expect(result.bookId, 'abc-123');
    });

    test('should extract bookId correctly in record mode', () {
      final uri = Uri(
          scheme: 'bookgolas', pathSegments: ['book', 'record', 'my-book-42']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNotNull);
      expect(result!.action, DeepLinkAction.bookRecord);
      expect(result.bookId, 'my-book-42');
    });
  });

  group('DeepLinkService.parseUri - invalid URIs', () {
    test('should return null for wrong scheme', () {
      final uri =
          Uri(scheme: 'https', pathSegments: ['book', 'detail', 'abc-123']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for empty path', () {
      final uri = Uri(scheme: 'bookgolas');
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for non-book first segment', () {
      final uri = Uri(scheme: 'bookgolas', pathSegments: ['settings', 'theme']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for unknown action', () {
      final uri = Uri(
          scheme: 'bookgolas', pathSegments: ['book', 'unknown', 'abc-123']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for detail without bookId', () {
      final uri = Uri(scheme: 'bookgolas', pathSegments: ['book', 'detail']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for record without bookId', () {
      final uri = Uri(scheme: 'bookgolas', pathSegments: ['book', 'record']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for only book segment', () {
      final uri = Uri(scheme: 'bookgolas', pathSegments: ['book']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });

    test('should return null for empty bookId in detail', () {
      final uri =
          Uri(scheme: 'bookgolas', pathSegments: ['book', 'detail', '']);
      final result = DeepLinkService.parseUri(uri);

      expect(result, isNull);
    });
  });

  group('DeepLinkResult', () {
    test('should store action and bookId correctly', () {
      const result =
          DeepLinkResult(action: DeepLinkAction.bookDetail, bookId: 'abc');

      expect(result.action, DeepLinkAction.bookDetail);
      expect(result.bookId, 'abc');
    });

    test('should allow null bookId for search action', () {
      const result = DeepLinkResult(action: DeepLinkAction.search);

      expect(result.action, DeepLinkAction.search);
      expect(result.bookId, isNull);
    });
  });

  group('DeepLinkAction enum', () {
    test('should have three values', () {
      expect(DeepLinkAction.values.length, 3);
    });

    test('should contain search, bookDetail, bookRecord', () {
      expect(DeepLinkAction.values, contains(DeepLinkAction.search));
      expect(DeepLinkAction.values, contains(DeepLinkAction.bookDetail));
      expect(DeepLinkAction.values, contains(DeepLinkAction.bookRecord));
    });
  });
}
