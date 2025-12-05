// lib/features/auth/data/repositories/document_repository_impl.dart
import 'package:book_tech/features/auth/data/models/model.dart';

import '../../domain/entities/document_entity.dart';
import '../../domain/entities/genre_entity.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../datasources/document_remote_data_source.dart';
import 'package:book_tech/core/services/cache_service.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;

  DocumentRepositoryImpl({required this.remoteDataSource});
  // get all documents for reader
  @override
  Future<List<DocumentEntity>> getDocumentsForReader({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  }) async {
    try {
      // Kiểm tra cache trước
      if (page == 1) {
        final cachedDocs = await CacheService.getDocumentsForReader(
          categoryName: categoryName,
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }

      // Fetch từ server
      final documents = await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken,
        page: page,
        limit: limit,
        categoryName: categoryName,
        documentType: documentType,
      );

      final entities = documents.map((doc) => doc.toEntity()).toList();

      // Lưu vào cache nếu là page 1
      if (page == 1) {
        final docsJson = documents.map((doc) => doc.toJson()).toList();
        await CacheService.saveDocumentsForReader(
          docsJson,
          categoryName: categoryName,
          documentType: documentType,
          page: page,
        );
      }

      return entities;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      if (page == 1) {
        final cachedDocs = await CacheService.getDocumentsForReader(
          categoryName: categoryName,
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // get documents by category
  @override
  Future<Map<GenreEntity, List<DocumentEntity>>> getDocumentsByCategory({
    required String accessToken,
  }) async {
    try {
      // Lấy tất cả documents
      final documents = await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken,
        limit: 100,
      );

      // Nhóm theo thể loại
      Map<GenreEntity, List<DocumentEntity>> groupedDocuments = {};

      for (final doc in documents) {
        // Tạo GenreEntity từ thông tin category của document
        final genre = GenreEntity(
          genreId: doc.documentId, // Sử dụng documentId làm genreId tạm thời
          name: doc.categoryName,
        );

        // Convert DocumentResponseModel to DocumentEntity
        final documentEntity = doc.toEntity();

        if (!groupedDocuments.containsKey(genre)) {
          groupedDocuments[genre] = [];
        }
        groupedDocuments[genre]!.add(documentEntity);
      }

      return groupedDocuments;
    } catch (e) {
      throw Exception('Failed to group documents by category: $e');
    }
  }

  // get documents by type
  @override
  Future<List<DocumentEntity>> getDocumentsByType({
    required String accessToken, // Thêm parameter này
    required String documentType,
  }) async {
    try {
      final documents = await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken, // Truyền token
        documentType: documentType,
        limit: 50,
      );
      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents by type: $e');
    }
  }

  // Lay chi tiet tai lieu
  @override
  Future<DocumentDetailModel> getDocumentDetail({
    required String accessToken,
    required int documentId,
  }) async {
    try {
      // ALWAYS fetch from server to get latest data (especially for availableCopies)
      // Cache is only used as fallback when network fails
      final response = await remoteDataSource.getDocumentDetail(
        accessToken: accessToken,
        documentId: documentId,
      );

      // Lưu vào cache
      await CacheService.saveDocumentDetail(documentId, response.toJson());

      return response;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      final cachedDetail = await CacheService.getDocumentDetail(documentId);
      if (cachedDetail != null) {
        return DocumentDetailModel.fromJson(cachedDetail);
      }
      throw Exception('Failed to fetch document detail: $e');
    }
  }

  // Thêm vào DocumentRepositoryImpl class
  @override
  Future<List<DocumentEntity>> getDocumentsByGenre({
    required String accessToken,
    required List<int> genreIds,
    String? documentType,
    int page = 1,
    int limit = 20,
    String match = 'any',
  }) async {
    try {
      final documents = await remoteDataSource.getDocumentsByGenre(
        accessToken: accessToken,
        genreIds: genreIds,
        documentType: documentType,
        page: page,
        limit: limit,
        match: match,
      );

      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents by genre: $e');
    }
  }

  // Thêm vào DocumentRepositoryImpl class, sau method getDocumentsByGenre:
  @override
  Future<List<GenreModel>> getGenres({required String accessToken}) async {
    try {
      final genres = await remoteDataSource.getGenres(accessToken: accessToken);

      return genres; // Trả về trực tiếp GenreModel từ remoteDataSource
    } catch (e) {
      throw Exception('Failed to fetch genres: $e');
    }
  }

  // Thêm method này vào DocumentRepositoryImpl class
  @override
  Future<List<DocumentEntity>> searchDocuments({
    required String accessToken,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Kiểm tra cache trước
      if (page == 1) {
        final cachedDocs = await CacheService.getSearchDocuments(
          query,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }

      // Fetch từ server
      final documents = await remoteDataSource.searchDocuments(
        accessToken: accessToken,
        query: query,
        page: page,
        limit: limit,
      );

      final entities = documents.map((doc) => doc.toEntity()).toList();

      // Lưu vào cache nếu là page 1
      if (page == 1) {
        final docsJson = documents.map((doc) => doc.toJson()).toList();
        await CacheService.saveSearchDocuments(query, docsJson, page: page);
      }

      return entities;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      if (page == 1) {
        final cachedDocs = await CacheService.getSearchDocuments(
          query,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }
      throw Exception('Failed to search documents: $e');
    }
  }

  // Thêm method getDocumentsBySearch nếu cần
  @override
  Future<List<DocumentEntity>> getDocumentsBySearch({
    required String accessToken,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final documents = await remoteDataSource.searchDocuments(
        accessToken: accessToken,
        query: query,
        page: page,
        limit: limit,
      );

      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }

  // Thêm implementation vào DocumentRepositoryImpl
  @override
  Future<String> getEbook({
    required String accessToken,
    required int documentId,
  }) async {
    try {
      final content = await remoteDataSource.getEbook(
        accessToken: accessToken,
        documentId: documentId,
      );

      return content;
    } catch (e) {
      throw Exception('Failed to fetch ebook: $e');
    }
  }

  // hien thi danh sach tai lieu tương tự
  @override
  Future<List<DocumentEntity>> getSimilarDocuments({
    required String accessToken,
    required int documentId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Kiểm tra cache trước
      if (page == 1) {
        final cachedDocs = await CacheService.getSimilarDocuments(documentId);
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }

      // Fetch từ server
      final documents = await remoteDataSource.getSimilarDocuments(
        accessToken: accessToken,
        documentId: documentId,
        page: page,
        limit: limit,
      );

      final entities = documents.map((doc) => doc.toEntity()).toList();

      // Lưu vào cache nếu là page 1
      if (page == 1) {
        final docsJson = documents.map((doc) => doc.toJson()).toList();
        await CacheService.saveSimilarDocuments(documentId, docsJson);
      }

      return entities;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      if (page == 1) {
        final cachedDocs = await CacheService.getSimilarDocuments(documentId);
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }
      throw Exception('Failed to fetch similar documents: $e');
    }
  }

  // Thêm implementation vào DocumentRepositoryImpl

  @override
  Future<Map<String, dynamic>> reserveBooks({
    required String accessToken,
    required List<Map<String, dynamic>> items,
  }) async {
    return await remoteDataSource.reserveBooks(
      accessToken: accessToken,
      items: items,
    );
  }

  // hien thi danh sach tai lieu moi nhat
  @override
  Future<List<DocumentEntity>> getNewDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  }) async {
    try {
      // Kiểm tra cache trước
      if (page == 1) {
        final cachedDocs = await CacheService.getNewDocuments(
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }

      // Fetch từ server
      final documents = await remoteDataSource.getNewDocuments(
        accessToken: accessToken,
        page: page,
        limit: limit,
        documentType: documentType,
      );

      final entities = documents.map((doc) => doc.toEntity()).toList();

      // Lưu vào cache nếu là page 1
      if (page == 1) {
        final docsJson = documents.map((doc) => doc.toJson()).toList();
        await CacheService.saveNewDocuments(
          docsJson,
          documentType: documentType,
          page: page,
        );
      }

      return entities;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      if (page == 1) {
        final cachedDocs = await CacheService.getNewDocuments(
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }
      throw Exception('Failed to fetch new documents: $e');
    }
  }

  // hien thi danh sach tai lieu duoc muon nhieu nhat
  @override
  Future<List<DocumentEntity>> getMostBorrowedDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  }) async {
    try {
      // Kiểm tra cache trước
      if (page == 1) {
        final cachedDocs = await CacheService.getMostBorrowedDocuments(
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }

      // Fetch từ server
      final documents = await remoteDataSource.getMostBorrowedDocuments(
        accessToken: accessToken,
        page: page,
        limit: limit,
        documentType: documentType,
      );

      final entities = documents.map((doc) => doc.toEntity()).toList();

      // Lưu vào cache nếu là page 1
      if (page == 1) {
        final docsJson = documents.map((doc) => doc.toJson()).toList();
        await CacheService.saveMostBorrowedDocuments(
          docsJson,
          documentType: documentType,
          page: page,
        );
      }

      return entities;
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      if (page == 1) {
        final cachedDocs = await CacheService.getMostBorrowedDocuments(
          documentType: documentType,
          page: page,
        );
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          return cachedDocs
              .map((json) => DocumentResponseModel.fromJson(json).toEntity())
              .toList();
        }
      }
      throw Exception('Failed to fetch most borrowed documents: $e');
    }
  }
}
