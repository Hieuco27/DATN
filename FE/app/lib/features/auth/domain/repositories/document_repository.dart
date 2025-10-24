// lib/features/auth/domain/repositories/document_repository.dart
import '../entities/document_entity.dart';
import '../entities/genre_entity.dart';
import '../../data/models/document_response_model.dart';

abstract class DocumentRepository {
  Future<List<DocumentEntity>> getDocumentsForReader({
    required String accessToken, // Thêm parameter này
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  });

  Future<Map<GenreEntity, List<DocumentEntity>>> getDocumentsByCategory({
    required String accessToken, // Thêm parameter này
  });

  Future<List<DocumentResponseModel>> getDocumentsByType({
    required String accessToken, // Thêm parameter này
    required String documentType,
  });
}
