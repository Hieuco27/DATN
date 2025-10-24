// lib/features/auth/presentations/providers/document_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Thêm import này
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_response_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentRepository repo;
  DocumentProvider(this.repo);

  bool _loading = false;
  String? _error;
  bool get isLoading => _loading;
  String? get error => _error;

  List<DocumentResponseModel> _books = [];
  List<DocumentResponseModel> _magazines = [];
  List<DocumentResponseModel> _newspapers = [];

  List<DocumentResponseModel> get books => _books;
  List<DocumentResponseModel> get magazines => _magazines;
  List<DocumentResponseModel> get newspapers => _newspapers;

  Future<void> loadPreviews(BuildContext context) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      final accessToken = authState.account.accessToken!;

      print('🔄 Loading documents by type...');

      final results = await Future.wait([
        repo.getDocumentsByType(accessToken: accessToken, documentType: 'book'),
        repo.getDocumentsByType(
          accessToken: accessToken,
          documentType: 'magazine',
        ),
        repo.getDocumentsByType(
          accessToken: accessToken,
          documentType: 'newspaper',
        ),
      ]);

      _books = results[0];
      _magazines = results[1];
      _newspapers = results[2];

      print('📚 Books loaded: ${_books.length}');
      print('📰 Magazines loaded: ${_magazines.length}');
      print('📰 Newspapers loaded: ${_newspapers.length}');

      // Debug: Check document types in each list
      for (var book in _books) {
        print('📚 Book: ${book.title} - Type: ${book.documentType}');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error in loadPreviews: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Map<String, List<DocumentResponseModel>> groupByCategoryName(
    List<DocumentResponseModel> docs,
  ) {
    final map = <String, List<DocumentResponseModel>>{};
    for (final d in docs) {
      map.putIfAbsent(d.categoryName, () => []).add(d);
    }
    return map;
  }
}
