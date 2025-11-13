import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service để cache dữ liệu vào local storage
class CacheService {
  static const String _genresKey = 'cached_genres';
  static const String _documentsByGenrePrefix = 'cached_docs_genre_';
  static const String _newDocumentsKey = 'cached_new_documents';
  static const String _mostBorrowedKey = 'cached_most_borrowed';
  static const String _documentDetailPrefix = 'cached_doc_detail_';
  static const String _similarDocumentsPrefix = 'cached_similar_docs_';
  static const String _searchDocumentsPrefix = 'cached_search_';
  static const String _documentsForReaderPrefix = 'cached_docs_reader_';
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
            return genresList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove(_genresKey);
            await prefs.remove('${_cacheTimestampPrefix}genres');
          }
        }
      }
      return null;
    } catch (e) {
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
    } catch (e) {}
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
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove('$_documentsByGenrePrefix$genreId');
            await prefs.remove('${_cacheTimestampPrefix}docs_$genreId');
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Xóa cache cho một genre cụ thể
  static Future<void> clearCacheForGenre(int genreId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_documentsByGenrePrefix$genreId');
      await prefs.remove('${_cacheTimestampPrefix}docs_$genreId');
    } catch (e) {}
  }

  /// Lưu new documents vào cache
  static Future<void> saveNewDocuments(
    List<Map<String, dynamic>> documents, {
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = documentType != null
          ? '${_newDocumentsKey}_${documentType}_$page'
          : '${_newDocumentsKey}_all_$page';
      final docsJson = json.encode(documents);
      await prefs.setString(key, docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}new_docs_${documentType ?? 'all'}_$page',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy new documents từ cache
  static Future<List<Map<String, dynamic>>?> getNewDocuments({
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = documentType != null
          ? '${_newDocumentsKey}_${documentType}_$page'
          : '${_newDocumentsKey}_all_$page';
      final docsJson = prefs.getString(key);

      if (docsJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}new_docs_${documentType ?? 'all'}_$page',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove(key);
            await prefs.remove(
              '${_cacheTimestampPrefix}new_docs_${documentType ?? 'all'}_$page',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu most borrowed documents vào cache
  static Future<void> saveMostBorrowedDocuments(
    List<Map<String, dynamic>> documents, {
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = documentType != null
          ? '${_mostBorrowedKey}_${documentType}_$page'
          : '${_mostBorrowedKey}_all_$page';
      final docsJson = json.encode(documents);
      await prefs.setString(key, docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}most_borrowed_${documentType ?? 'all'}_$page',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy most borrowed documents từ cache
  static Future<List<Map<String, dynamic>>?> getMostBorrowedDocuments({
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = documentType != null
          ? '${_mostBorrowedKey}_${documentType}_$page'
          : '${_mostBorrowedKey}_all_$page';
      final docsJson = prefs.getString(key);

      if (docsJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}most_borrowed_${documentType ?? 'all'}_$page',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove(key);
            await prefs.remove(
              '${_cacheTimestampPrefix}most_borrowed_${documentType ?? 'all'}_$page',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu document detail vào cache
  static Future<void> saveDocumentDetail(
    int documentId,
    Map<String, dynamic> documentDetail,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final detailJson = json.encode(documentDetail);
      await prefs.setString('$_documentDetailPrefix$documentId', detailJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}doc_detail_$documentId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy document detail từ cache
  static Future<Map<String, dynamic>?> getDocumentDetail(int documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final detailJson = prefs.getString('$_documentDetailPrefix$documentId');

      if (detailJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}doc_detail_$documentId',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            return json.decode(detailJson) as Map<String, dynamic>;
          } else {
            await prefs.remove('$_documentDetailPrefix$documentId');
            await prefs.remove(
              '${_cacheTimestampPrefix}doc_detail_$documentId',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu similar documents vào cache
  static Future<void> saveSimilarDocuments(
    int documentId,
    List<Map<String, dynamic>> documents,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = json.encode(documents);
      await prefs.setString('$_similarDocumentsPrefix$documentId', docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}similar_docs_$documentId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy similar documents từ cache
  static Future<List<Map<String, dynamic>>?> getSimilarDocuments(
    int documentId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = prefs.getString('$_similarDocumentsPrefix$documentId');

      if (docsJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}similar_docs_$documentId',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove('$_similarDocumentsPrefix$documentId');
            await prefs.remove(
              '${_cacheTimestampPrefix}similar_docs_$documentId',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu search results vào cache
  static Future<void> saveSearchDocuments(
    String query,
    List<Map<String, dynamic>> documents, {
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_searchDocumentsPrefix}${query.toLowerCase()}_$page';
      final docsJson = json.encode(documents);
      await prefs.setString(key, docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}search_${query.toLowerCase()}_$page',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy search results từ cache
  static Future<List<Map<String, dynamic>>?> getSearchDocuments(
    String query, {
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_searchDocumentsPrefix}${query.toLowerCase()}_$page';
      final docsJson = prefs.getString(key);

      if (docsJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}search_${query.toLowerCase()}_$page',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove(key);
            await prefs.remove(
              '${_cacheTimestampPrefix}search_${query.toLowerCase()}_$page',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu documents for reader vào cache
  static Future<void> saveDocumentsForReader(
    List<Map<String, dynamic>> documents, {
    String? categoryName,
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          '${_documentsForReaderPrefix}${categoryName ?? 'all'}_${documentType ?? 'all'}_$page';
      final docsJson = json.encode(documents);
      await prefs.setString(key, docsJson);
      await prefs.setInt(
        '${_cacheTimestampPrefix}docs_reader_${categoryName ?? 'all'}_${documentType ?? 'all'}_$page',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Lấy documents for reader từ cache
  static Future<List<Map<String, dynamic>>?> getDocumentsForReader({
    String? categoryName,
    String? documentType,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          '${_documentsForReaderPrefix}${categoryName ?? 'all'}_${documentType ?? 'all'}_$page';
      final docsJson = prefs.getString(key);

      if (docsJson != null) {
        final timestamp = prefs.getInt(
          '${_cacheTimestampPrefix}docs_reader_${categoryName ?? 'all'}_${documentType ?? 'all'}_$page',
        );
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          if (now.difference(cacheTime) < _defaultCacheDuration) {
            final List<dynamic> docsList = json.decode(docsJson);
            return docsList.cast<Map<String, dynamic>>();
          } else {
            await prefs.remove(key);
            await prefs.remove(
              '${_cacheTimestampPrefix}docs_reader_${categoryName ?? 'all'}_${documentType ?? 'all'}_$page',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
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
                key.startsWith(_newDocumentsKey) ||
                key.startsWith(_mostBorrowedKey) ||
                key.startsWith(_documentDetailPrefix) ||
                key.startsWith(_similarDocumentsPrefix) ||
                key.startsWith(_searchDocumentsPrefix) ||
                key.startsWith(_documentsForReaderPrefix) ||
                key.startsWith(_cacheTimestampPrefix),
          )
          .toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {}
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
