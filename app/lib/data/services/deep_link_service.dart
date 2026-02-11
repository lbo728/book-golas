import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const _deepLinkChannel = MethodChannel('com.bookgolas.app/deep_link');

  static DeepLinkResult? parseUri(Uri uri) {
    if (uri.scheme != 'bookgolas') return null;

    final segments = _extractSegments(uri);
    if (segments.isEmpty) return null;

    if (segments.first != 'book') return null;

    if (segments.length == 2 && segments[1] == 'search') {
      return const DeepLinkResult(action: DeepLinkAction.search);
    }

    if (segments.length == 3 && segments[1] == 'detail') {
      final bookId = segments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookDetail,
          bookId: bookId,
        );
      }
    }

    if (segments.length == 3 && segments[1] == 'record') {
      final bookId = segments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookRecord,
          bookId: bookId,
        );
      }
    }

    if (segments.length == 3 && segments[1] == 'scan') {
      final bookId = segments[2];
      if (bookId.isNotEmpty) {
        return DeepLinkResult(
          action: DeepLinkAction.bookScan,
          bookId: bookId,
        );
      }
    }

    return null;
  }

  static List<String> _extractSegments(Uri uri) {
    if (uri.host.isNotEmpty) {
      return [uri.host, ...uri.pathSegments];
    }
    return uri.pathSegments;
  }

  static Future<void> init(
    BuildContext context, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;
    _setupNativeDeepLinkChannel();
    await _initWidgetClickHandler();
    await _initAppLinks();
  }

  static void _setupNativeDeepLinkChannel() {
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final urlString = call.arguments as String;
        final uri = Uri.parse(urlString);
        debugPrint('📱 네이티브 딥링크 수신: $uri');
        await _handleDeepLink(uri);
      }
    });
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

  static Future<String?> _resolveBookId(String? bookId) async {
    if (bookId == null) return null;
    if (bookId != 'current') return bookId;

    try {
      final storedId = await HomeWidget.getWidgetData<String>('book_id');
      if (storedId != null && storedId.isNotEmpty) {
        debugPrint('🔗 "current" → 위젯 저장 책 ID: $storedId');
        return storedId;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('books')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'reading')
            .isFilter('deleted_at', null)
            .order('updated_at', ascending: false)
            .limit(1);
        if ((response as List).isNotEmpty) {
          final id = response.first['id'] as String;
          debugPrint('🔗 "current" → DB 첫 reading 책 ID: $id');
          return id;
        }
      }
    } catch (e) {
      debugPrint('🔗 "current" bookId 해석 실패: $e');
    }
    return null;
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
        final resolvedId = await _resolveBookId(result.bookId);
        if (resolvedId == null) return;
        final book = await _fetchBook(resolvedId);
        if (book == null) {
          debugPrint('🔗 책을 찾을 수 없음: $resolvedId');
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          ),
        );
        break;

      case DeepLinkAction.bookRecord:
        final resolvedRecordId = await _resolveBookId(result.bookId);
        if (resolvedRecordId == null) return;
        final recordBook = await _fetchBook(resolvedRecordId);
        if (recordBook == null) {
          debugPrint('🔗 책을 찾을 수 없음: $resolvedRecordId');
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
        final resolvedScanId = await _resolveBookId(result.bookId);
        if (resolvedScanId == null) return;
        final scanBook = await _fetchBook(resolvedScanId);
        if (scanBook == null) {
          debugPrint('🔗 책을 찾을 수 없음: $resolvedScanId');
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
