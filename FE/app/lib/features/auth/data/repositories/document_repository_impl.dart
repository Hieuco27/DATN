// lib/features/auth/data/repositories/document_repository_impl.dart
import 'package:book_tech/features/auth/data/models/model.dart';

import '../../domain/entities/document_entity.dart';
import '../../domain/entities/genre_entity.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../datasources/document_remote_data_source.dart';
import '../models/document_response_model.dart';
import '../models/document_detail_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;

  DocumentRepositoryImpl({required this.remoteDataSource});
  // get all documents for reader
  @override
  Future<List<DocumentEntity>> getDocumentsForReader({
    required String accessToken, // Thêm parameter này
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  }) async {
    try {
      print('📚 Fetching documents for reader...');

      final documents = await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken, // Truyền token
        page: page,
        limit: limit,
        categoryName: categoryName,
        documentType: documentType,
      );

      print('📚 Fetched ${documents.length} documents');

      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      print('❌ Error in repository: $e');
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // get documents by category
  @override
  Future<Map<GenreEntity, List<DocumentEntity>>> getDocumentsByCategory({
    required String accessToken, // Thêm parameter này
  }) async {
    try {
      print('📚 Grouping documents by category...');

      // Lấy tất cả documents
      final documents = await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken, // Truyền token
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

      print('📚 Grouped into ${groupedDocuments.length} categories');

      return groupedDocuments;
    } catch (e) {
      print('❌ Error grouping documents: $e');
      throw Exception('Failed to group documents by category: $e');
    }
  }

  // get documents by type
  @override
  Future<List<DocumentResponseModel>> getDocumentsByType({
    required String accessToken, // Thêm parameter này
    required String documentType,
  }) async {
    try {
      return await remoteDataSource.getDocumentsForReader(
        accessToken: accessToken, // Truyền token
        documentType: documentType,
        limit: 50,
      );
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
      print('📚 Fetching document detail for ID: $documentId');

      final response = await remoteDataSource.getDocumentDetail(
        accessToken: accessToken,
        documentId: documentId,
      );

      print('📚 Document detail fetched successfully');
      return response;
    } catch (e) {
      print('❌ Error fetching document detail: $e');
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
      print('📚 Fetching documents by genre...');

      final documents = await remoteDataSource.getDocumentsByGenre(
        accessToken: accessToken,
        genreIds: genreIds,
        documentType: documentType,
        page: page,
        limit: limit,
        match: match,
      );

      print('📚 Fetched ${documents.length} documents by genre');

      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      print('❌ Error in repository: $e');
      throw Exception('Failed to fetch documents by genre: $e');
    }
  }

  // Thêm vào DocumentRepositoryImpl class, sau method getDocumentsByGenre:
  @override
  Future<List<GenreModel>> getGenres({required String accessToken}) async {
    try {
      print('🎭 Fetching genres...');

      final genres = await remoteDataSource.getGenres(accessToken: accessToken);

      print('🎭 Fetched ${genres.length} genres');

      return genres; // Trả về trực tiếp GenreModel từ remoteDataSource
    } catch (e) {
      print('❌ Error in repository: $e');
      throw Exception('Failed to fetch genres: $e');
    }
  }

  // Thêm method này vào DocumentRepositoryImpl class
  @override
  Future<List<DocumentResponseModel>> searchDocuments({
    required String accessToken,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 Searching documents for query: "$query"');

      final documents = await remoteDataSource.searchDocuments(
        accessToken: accessToken,
        query: query,
        page: page,
        limit: limit,
      );

      print('🔍 Found ${documents.length} search results');
      return documents;
    } catch (e) {
      print('❌ Error in search repository: $e');
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
      print('🔍 Searching documents by search for query: "$query"');

      final documents = await remoteDataSource.searchDocuments(
        accessToken: accessToken,
        query: query,
        page: page,
        limit: limit,
      );

      print('🔍 Found ${documents.length} search results');
      return documents.map((doc) => doc.toEntity()).toList();
    } catch (e) {
      print('❌ Error in search repository: $e');
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
      print('📖 Fetching ebook content for document: $documentId');

      final content = await remoteDataSource.getEbook(
        accessToken: accessToken,
        documentId: documentId,
      );

      print('📖 Fetched ebook content: ${content.length} characters');
      return content;
    } catch (e) {
      print('❌ Error in repository: $e');
      throw Exception('Failed to fetch ebook: $e');
    }
  }
}
