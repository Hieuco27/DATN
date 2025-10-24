// lib/features/auth/data/repositories/document_repository_impl.dart
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/genre_entity.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../datasources/document_remote_data_source.dart';
import '../models/document_response_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;

  DocumentRepositoryImpl({required this.remoteDataSource});

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
          documentType: doc.documentType,
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
}
