import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/book.dart';

class WidgetDataService {
  static final WidgetDataService _instance = WidgetDataService._internal();
  factory WidgetDataService() => _instance;
  WidgetDataService._internal();

  static const String _widgetName = 'BookgolasWidget';

  Future<void> syncCurrentBook(Book book) async {
    try {
      final localImagePath = await cacheBookCoverToAppGroup(book.imageUrl);

      await HomeWidget.saveWidgetData<String>('book_id', book.id ?? '');
      await HomeWidget.saveWidgetData<String>('book_title', book.title);
      await HomeWidget.saveWidgetData<String>('book_author', book.author ?? '');
      await HomeWidget.saveWidgetData<String>(
          'current_page', book.currentPage.toString());
      await HomeWidget.saveWidgetData<String>(
          'total_pages', book.totalPages.toString());
      await HomeWidget.saveWidgetData<String>(
          'image_path', localImagePath ?? '');
      await HomeWidget.saveWidgetData<String>('book_status', book.status ?? '');
      await HomeWidget.saveWidgetData<String>(
          'last_updated', DateTime.now().toIso8601String());

      await refreshWidget();

      debugPrint('📱 [WidgetDataService] 위젯 데이터 동기화 완료: ${book.title}');
    } catch (e) {
      debugPrint('📱 [WidgetDataService] 위젯 데이터 동기화 실패: $e');
    }
  }

  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('book_id', '');
      await HomeWidget.saveWidgetData<String>('book_title', '');
      await HomeWidget.saveWidgetData<String>('book_author', '');
      await HomeWidget.saveWidgetData<String>('current_page', '');
      await HomeWidget.saveWidgetData<String>('total_pages', '');
      await HomeWidget.saveWidgetData<String>('image_path', '');
      await HomeWidget.saveWidgetData<String>('book_status', '');
      await HomeWidget.saveWidgetData<String>('last_updated', '');
      await HomeWidget.saveWidgetData<bool>('needs_sync', false);

      await refreshWidget();

      debugPrint('📱 [WidgetDataService] 위젯 데이터 초기화 완료');
    } catch (e) {
      debugPrint('📱 [WidgetDataService] 위젯 데이터 초기화 실패: $e');
    }
  }

  Future<void> refreshWidget() async {
    try {
      await HomeWidget.updateWidget(name: _widgetName);
      debugPrint('📱 [WidgetDataService] 위젯 갱신 요청 완료');
    } catch (e) {
      debugPrint('📱 [WidgetDataService] 위젯 갱신 실패: $e');
    }
  }

  Future<String?> cacheBookCoverToAppGroup(String? networkUrl) async {
    if (networkUrl == null || networkUrl.isEmpty) return null;

    try {
      final file = await DefaultCacheManager().getSingleFile(networkUrl);
      final appDir = await getApplicationSupportDirectory();
      final widgetImageDir = Directory('${appDir.path}/widget_images');

      if (!widgetImageDir.existsSync()) {
        widgetImageDir.createSync(recursive: true);
      }

      final extension = file.path.split('.').last;
      final localPath = '${widgetImageDir.path}/book_cover.$extension';
      final localFile = await file.copy(localPath);

      debugPrint('📱 [WidgetDataService] 커버 이미지 캐시 완료: ${localFile.path}');
      return localFile.path;
    } catch (e) {
      debugPrint('📱 [WidgetDataService] 커버 이미지 캐시 실패: $e');
      return null;
    }
  }

  Future<void> handleNeedsSyncFlag() async {
    try {
      final needsSync =
          await HomeWidget.getWidgetData<bool>('needs_sync') ?? false;

      if (!needsSync) return;

      final bookId = await HomeWidget.getWidgetData<String>('book_id');
      final currentPageStr =
          await HomeWidget.getWidgetData<String>('current_page');

      if (bookId == null ||
          bookId.isEmpty ||
          currentPageStr == null ||
          currentPageStr.isEmpty) {
        return;
      }

      final currentPage = int.tryParse(currentPageStr);
      if (currentPage == null) return;

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('books').update({
        'current_page': currentPage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookId);

      await HomeWidget.saveWidgetData<bool>('needs_sync', false);

      debugPrint(
          '📱 [WidgetDataService] 위젯 → Supabase 동기화 완료: bookId=$bookId, page=$currentPage');
    } catch (e) {
      debugPrint('📱 [WidgetDataService] needs_sync 처리 실패: $e');
    }
  }
}
