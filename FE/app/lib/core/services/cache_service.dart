import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service để cache dữ liệu vào local storage
class CacheService {
  static const String _genresKey = 'cached_genres';
  static const String _documentsByGenrePrefix = 'cached_docs_genre_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  /// Lưu genres vào cache
  static Future<void> saveGenres(List<Map<String, dynamic>> genres) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final genresJson = json.encode(genres);
      await prefs.setString(_genresKey, genresJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}genres',
        DateTime.now().millisecondsSinceEpoch,
      );
      print('💾 Genres cached: ${genres.length} items');
    } catch (e) {
      print('❌ Error caching genres: $e');
    }
  }

  /// Lấy genres từ cache
  static Future<List<Map<String, dynamic>>?> getGenres() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final genresJson = prefs.getString(_genresKey);

      if (genresJson != null) {
        // Kiểm tra thời gian cache
        final timestamp = prefs.getInt('${_cacheTimestampPrefix}genres');
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> genresList = json.decode(genresJson);
            print('📦 Genres loaded from cache: ${genresList.length} items');
            return genresList.cast<Map<String, dynamic>>();
          } else {
            print('⏰ Genres cache expired');
            await prefs.remove(_genresKey);
            await prefs.remove('${_cacheTimestampPrefix}genres');
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error loading cached genres: $e');
      return null;
    }
  }

  /// Lưu documents theo genre vào cache
  static Future<void> saveDocumentsByGenre(
    int genreId,
    List<Map<String, dynamic>> documents,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = json.encode(documents);
      await prefs.setString('$_documentsByGenrePrefix$genreId', docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}docs_$genreId',
        DateTime.now().millisecondsSinceEpoch,
      );
      print(
        '💾 Documents cached for genre $genreId: ${documents.length} items',
      );
    } catch (e) {
      print('❌ Error caching documents: $e');
    }
  }

  /// Lấy documents theo genre từ cache
  static Future<List<Map<String, dynamic>>?> getDocumentsByGenre(
    int genreId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = prefs.getString('$_documentsByGenrePrefix$genreId');

      if (docsJson != null) {
        // Kiểm tra thời gian cache
        final timestamp = prefs.getInt('${_cacheTimestampPrefix}docs_$genreId');
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            print(
              '📦 Documents loaded from cache for genre $genreId: ${docsList.length} items',
            );
            return docsList.cast<Map<String, dynamic>>();
          } else {
            print('⏰ Documents cache expired for genre $genreId');
            await prefs.remove('$_documentsByGenrePrefix$genreId');
            await prefs.remove('${_cacheTimestampPrefix}docs_$genreId');
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error loading cached documents: $e');
      return null;
    }
  }

  /// Xóa cache cho một genre cụ thể
  static Future<void> clearCacheForGenre(int genreId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_documentsByGenrePrefix$genreId');
      await prefs.remove('${_cacheTimestampPrefix}docs_$genreId');
      print('🗑️ Cache cleared for genre $genreId');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Xóa tất cả cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final keysToRemove = keys
          .where(
            (key) =>
                key.startsWith(_genresKey) ||
                key.startsWith(_documentsByGenrePrefix) ||
                key.startsWith(_cacheTimestampPrefix),
          )
          .toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      print('🗑️ All cache cleared: ${keysToRemove.length} keys');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// Kiểm tra xem cache có tồn tại và còn hạn không
  static Future<bool> hasValidCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_cacheTimestampPrefix}$cacheKey');

      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        return now.difference(cacheTime) < _defaultCacheDuration;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
