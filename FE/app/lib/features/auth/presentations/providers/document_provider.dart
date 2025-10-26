// lib/features/auth/presentations/providers/document_provider.dart
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/domain/entities/genre_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Thêm import này
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_response_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

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

  // Get documents by genre với cache
  Future<List<DocumentEntity>> getDocumentsByGenre({
    required String accessToken,
    required int genreId,
    String? documentType,
    int page = 1,
    int limit = 20,
    bool useCache = true,
  }) async {
    // Kiểm tra cache trước
    if (useCache &&
        _documentsByGenre.containsKey(genreId) &&
        !(_isLoadingByGenre[genreId] ?? false)) {
      return _documentsByGenre[genreId]!;
    }

    // Set loading state
    _isLoadingByGenre[genreId] = true;
    notifyListeners();

    try {
      final documents = await _documentRepository.getDocumentsByGenre(
        accessToken: accessToken,
        genreIds: [genreId],
        documentType: documentType,
        page: page,
        limit: limit,
        match: 'any',
      );

      // Cache kết quả
      _documentsByGenre[genreId] = documents;
      return documents;
    } catch (e) {
      print('❌ Error loading documents by genre: $e');
      return [];
    } finally {
      _isLoadingByGenre[genreId] = false;
      notifyListeners();
    }
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
      print('❌ Error loading documents: $e');
      return [];
    }
  }

  // Thêm method này vào DocumentProvider nếu chưa có:
  Future<void> loadGenres(BuildContext context) async {
    _isLoadingGenres = true;
    notifyListeners();

    try {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        final authState = authBloc.state as AuthAuthenticated;
        _genres = await _documentRepository.getGenres(
          accessToken: authState.account.accessToken!,
        );
      }
    } catch (e) {
      print('❌ Error loading genres: $e');
    } finally {
      _isLoadingGenres = false;
      notifyListeners();
    }
  }
}
