import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 커스텀 이미지 캐시 매니저
/// stale time: 10분, max age: 7일
class BookImageCacheManager {
  static const key = 'bookImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(minutes: 10),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
