import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';
import 'package:book_golas/ui/reading_start/widgets/reading_start_screen.dart';

enum DeepLinkAction {
  search,
  bookDetail,
  bookRecord,
  bookScan,
}

class DeepLinkResult {
  final DeepLinkAction action;
  final String? bookId;

  const DeepLinkResult({required this.action, this.bookId});
}

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static StreamSubscription<Uri?>? _widgetClickSubscription;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static DeepLinkResult? parseUri(Uri uri) {
    if (uri.scheme != 'bookgolas') return null;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    if (pathSegments.first != 'book') return null;

    if (pathSegments.length == 2 && pathSegments[1] == 'search') {
      return const DeepLinkResult(action: DeepLinkAction.search);
    }

    if (pathSegments.length == 3 && pathSegments[1] == 'detail') {
      final bookId = pathSegments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookDetail,
          bookId: bookId,
        );
      }
    }

    if (pathSegments.length == 3 && pathSegments[1] == 'record') {
      final bookId = pathSegments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookRecord,
          bookId: bookId,
        );
      }
    }

    if (pathSegments.length == 3 && pathSegments[1] == 'scan') {
      final bookId = pathSegments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookScan,
          bookId: bookId,
        );
      }
    }

    return null;
  }

  static Future<void> init(
    BuildContext context, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;
    await _initWidgetClickHandler();
    await _initAppLinks();
  }

  static NavigatorState? get _navigator => _navigatorKey?.currentState;

  static Future<void> _initWidgetClickHandler() async {
    try {
      final initialWidgetUri =
          await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialWidgetUri != null) {
        debugPrint('📱 위젯 콜드스타트 딥링크: $initialWidgetUri');
        await _handleDeepLink(initialWidgetUri);
      }
    } catch (e) {
      debugPrint('📱 위젯 초기 링크 처리 실패: $e');
    }

    _widgetClickSubscription?.cancel();
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      (Uri? uri) {
        if (uri != null) {
          debugPrint('📱 위젯 클릭 딥링크: $uri');
          _handleDeepLink(uri);
        }
      },
      onError: (e) {
        debugPrint('📱 위젯 클릭 스트림 에러: $e');
      },
    );
  }

  static Future<void> _initAppLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('🔗 딥링크 초기 링크 처리 실패: $e');
    }

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (e) {
        debugPrint('🔗 딥링크 스트림 에러: $e');
      },
    );
  }

  static Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('🔗 딥링크 수신: $uri');

    final navigator = _navigator;
    if (navigator == null) {
      debugPrint('🔗 Navigator 없음 — 딥링크 무시');
      return;
    }

    final result = parseUri(uri);
    if (result == null) {
      debugPrint('🔗 유효하지 않은 딥링크: $uri');
      return;
    }

    switch (result.action) {
      case DeepLinkAction.search:
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const ReadingStartScreen(),
          ),
        );
        break;

      case DeepLinkAction.bookDetail:
        if (result.bookId == null) return;
        final book = await _fetchBook(result.bookId!);
        if (book == null) {
          debugPrint('🔗 책을 찾을 수 없음: ${result.bookId}');
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          ),
        );
        break;

      case DeepLinkAction.bookRecord:
        if (result.bookId == null) return;
        final recordBook = await _fetchBook(result.bookId!);
        if (recordBook == null) {
          debugPrint('🔗 책을 찾을 수 없음: ${result.bookId}');
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              book: recordBook,
              initialTabIndex: 1,
            ),
          ),
        );
        break;

      case DeepLinkAction.bookScan:
        if (result.bookId == null) return;
        final scanBook = await _fetchBook(result.bookId!);
        if (scanBook == null) {
          debugPrint('🔗 책을 찾을 수 없음: ${result.bookId}');
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              book: scanBook,
              autoOpenScan: true,
            ),
          ),
        );
        break;
    }
  }

  static Future<Book?> _fetchBook(String bookId) async {
    try {
      final bookService = BookService();
      return await bookService.getBookById(bookId);
    } catch (e) {
      debugPrint('🔗 딥링크 책 조회 실패: $e');
      return null;
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _widgetClickSubscription?.cancel();
    _widgetClickSubscription = null;
    _navigatorKey = null;
  }
}
