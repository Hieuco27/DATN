// lib/features/auth/presentations/providers/document_provider.dart
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/data/models/document_model.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/domain/entities/genre_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Thêm import này
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_response_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'package:book_tech/core/services/cache_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentRepository _documentRepository;
  DocumentProvider(this._documentRepository);

  //Genres
  List<GenreModel> _genres = [];
  List<GenreModel> get genres => _genres;
  bool _isLoadingGenres = false;
  bool get isLoadingGenres => _isLoadingGenres;

  get error => null;
  Map<int, List<DocumentEntity>> _documentsByGenre = {};
  Map<int, bool> _isLoadingByGenre = {};

  // Get documents by genre với cache từ disk
  Future<List<DocumentEntity>> getDocumentsByGenre({
    required String accessToken,
    required int genreId,
    String? documentType,
    int page = 1,
    int limit = 20,
    bool useCache = true,
  }) async {
    // 1. Kiểm tra cache trong memory trước
    if (useCache &&
        _documentsByGenre.containsKey(genreId) &&
        !(_isLoadingByGenre[genreId] ?? false)) {
      return _documentsByGenre[genreId]!;
    }

    // Set loading state
    _isLoadingByGenre[genreId] = true;
    // Defer notifyListeners() to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // 2. Thử load từ disk cache
      if (useCache && page == 1) {
        final cachedDocs = await CacheService.getDocumentsByGenre(genreId);
        if (cachedDocs != null && cachedDocs.isNotEmpty) {
          final documents = cachedDocs
              .map((json) => DocumentModel.fromJson(json))
              .toList();
          _documentsByGenre[genreId] = documents;
          _isLoadingByGenre[genreId] = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });

          // Load từ server ở background để cập nhật cache
          _loadDocumentsFromServer(
            accessToken,
            genreId,
            documentType,
            page,
            limit,
          );

          return documents;
        }
      }

      // 3. Load từ server
      return await _loadDocumentsFromServer(
        accessToken,
        genreId,
        documentType,
        page,
        limit,
      );
    } catch (e) {
      return [];
    } finally {
      _isLoadingByGenre[genreId] = false;
      // Defer notifyListeners() to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Helper method để load từ server và cache
  Future<List<DocumentEntity>> _loadDocumentsFromServer(
    String accessToken,
    int genreId,
    String? documentType,
    int page,
    int limit,
  ) async {
    final documents = await _documentRepository.getDocumentsByGenre(
      accessToken: accessToken,
      genreIds: [genreId],
      documentType: documentType,
      page: page,
      limit: limit,
      match: 'any',
    );

    // Cache kết quả vào memory
    _documentsByGenre[genreId] = documents;

    // Cache vào disk nếu là page 1 (tránh cache nhiều page)
    if (page == 1) {
      final docsJson = documents
          .whereType<DocumentModel>()
          .map((doc) => doc.toJson())
          .toList();
      await CacheService.saveDocumentsByGenre(genreId, docsJson);
    }

    return documents;
  }

  // Check if loading for specific genre
  bool isLoadingGenre(int genreId) {
    return _isLoadingByGenre[genreId] ?? false;
  }

  // Get cached documents for genre
  List<DocumentEntity> getCachedDocumentsByGenre(int genreId) {
    return _documentsByGenre[genreId] ?? [];
  }

  // Thêm method này vào DocumentProvider class
  Future<List<DocumentEntity>> getDocumentsForReader({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  }) async {
    try {
      final documents = await _documentRepository.getDocumentsForReader(
        accessToken: accessToken,
        page: page,
        limit: limit,
        categoryName: categoryName,
        documentType: documentType,
      );
      return documents;
    } catch (e) {
      return [];
    }
  }

  // Load genres với cache từ disk
  Future<void> loadGenres(BuildContext context) async {
    // Kiểm tra nếu đã có trong memory
    if (_genres.isNotEmpty) {
      return;
    }

    _isLoadingGenres = true;
    notifyListeners();

    try {
      // 1. Thử load từ cache trước
      final cachedGenres = await CacheService.getGenres();
      if (cachedGenres != null && cachedGenres.isNotEmpty) {
        _genres = cachedGenres
            .map((json) => GenreModel.fromJson(json))
            .toList();
        _isLoadingGenres = false;
        notifyListeners();
      }

      // 2. Load từ server
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        final authState = authBloc.state as AuthAuthenticated;
        final serverGenres = await _documentRepository.getGenres(
          accessToken: authState.account.accessToken!,
        );

        // 3. Lưu vào cache
        final genresJson = serverGenres.map((g) => g.toJson()).toList();
        await CacheService.saveGenres(genresJson);

        _genres = serverGenres;
      }
    } catch (e) {
      // Nếu có cache thì vẫn dùng được
      if (_genres.isEmpty) {}
    } finally {
      _isLoadingGenres = false;
      notifyListeners();
    }
  }
}
