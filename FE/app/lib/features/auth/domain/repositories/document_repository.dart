// lib/features/auth/domain/repositories/document_repository.dart
import 'package:book_tech/features/auth/data/models/genre_model.dart';

import '../entities/document_entity.dart';
import '../entities/genre_entity.dart';
import '../../data/models/document_detail_model.dart';

abstract class DocumentRepository {
  // get all documents for reader
  Future<List<DocumentEntity>> getDocumentsForReader({
    required String accessToken, // Thêm parameter này
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  });

  // get documents by category
  Future<Map<GenreEntity, List<DocumentEntity>>> getDocumentsByCategory({
    required String accessToken,
  });
  // get documents by type
  Future<List<DocumentEntity>> getDocumentsByType({
    required String accessToken,
    required String documentType,
  });
  // Thêm method tìm kiếm
  Future<List<DocumentEntity>> searchDocuments({
    required String accessToken,
    required String query,
    int page = 1,
    int limit = 20,
  });
  // Lay chi tiet tai lieu
  Future<DocumentDetailModel> getDocumentDetail({
    required String accessToken,
    required int documentId,
  });
  // Thêm vào abstract class DocumentRepository
  Future<List<DocumentEntity>> getDocumentsByGenre({
    required String accessToken,
    required List<int> genreIds,
    String? documentType,
    int page = 1,
    int limit = 20,
    String match = 'any',
  });
  Future<List<GenreModel>> getGenres({required String accessToken});
  Future<List<DocumentEntity>> getDocumentsBySearch({
    required String accessToken,
    required String query,
    int page = 1,
    int limit = 20,
  });
  Future<String> getEbook({
    required String accessToken,
    required int documentId,
  });
  // Thêm vào abstract class DocumentRepository
  Future<List<DocumentEntity>> getSimilarDocuments({
    required String accessToken,
    required int documentId,
    int page = 1,
    int limit = 10,
  });

  // Thêm vào abstract class DocumentRepository
  Future<Map<String, dynamic>> reserveBooks({
    required String accessToken,
    required List<Map<String, dynamic>>
    items, // [{documentId: int, quantity: int}]
  });
  Future<List<DocumentEntity>> getNewDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  });
  // hien thi danh sach tai lieu duoc muon nhieu nhat
  Future<List<DocumentEntity>> getMostBorrowedDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  });
}
