import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/reading_record.dart';

class RecordService {
  static final RecordService _instance = RecordService._internal();
  factory RecordService() => _instance;
  RecordService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'reading_content_embeddings';

  Future<List<ReadingRecord>> fetchAllRecords({String? contentType}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from(_tableName)
          .select('*, books(title, image_url)')
          .eq('user_id', userId);

      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReadingRecord.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('기록 조회 실패: $e');
      return [];
    }
  }

  Future<List<GroupedRecords>> fetchGroupedRecords({
    String? contentType,
  }) async {
    try {
      final records = await fetchAllRecords(contentType: contentType);

      final groupMap = <String, List<ReadingRecord>>{};
      final bookInfoMap = <String, (String, String?)>{};

      for (final record in records) {
        if (!groupMap.containsKey(record.bookId)) {
          groupMap[record.bookId] = [];
          bookInfoMap[record.bookId] = (record.bookTitle, record.bookImageUrl);
        }
        groupMap[record.bookId]!.add(record);
      }

      final grouped = groupMap.entries.map((entry) {
        final bookInfo = bookInfoMap[entry.key]!;
        return GroupedRecords(
          bookId: entry.key,
          bookTitle: bookInfo.$1,
          bookImageUrl: bookInfo.$2,
          records: entry.value,
        );
      }).toList();

      grouped.sort((a, b) {
        final aLatest =
            a.records.isNotEmpty ? a.records.first.createdAt : DateTime(1970);
        final bLatest =
            b.records.isNotEmpty ? b.records.first.createdAt : DateTime(1970);
        return bLatest.compareTo(aLatest);
      });

      return grouped;
    } catch (e) {
      debugPrint('그룹화된 기록 조회 실패: $e');
      return [];
    }
  }

  Future<int> getTotalRecordCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response =
          await _supabase.from(_tableName).select('id').eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('기록 개수 조회 실패: $e');
      return 0;
    }
  }
}
