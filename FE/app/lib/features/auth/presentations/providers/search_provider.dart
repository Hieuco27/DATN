import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_response_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SearchProvider with ChangeNotifier {
  final DocumentRepository repository;
  SearchProvider(this.repository);

  bool _isLoading = false;
  String? _error;
  List<DocumentResponseModel> _searchResults = [];
  String _currentQuery = '';
  List<String> _searchHistory = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DocumentResponseModel> get searchResults => _searchResults;
  String get currentQuery => _currentQuery;
  List<String> get searchHistory => _searchHistory;

  Future<void> searchDocuments(String query, BuildContext context) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _currentQuery = query.trim();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      print('🔍 Starting search for: "$query"');
      print('🔑 Token: ${authState.account.accessToken!.substring(0, 20)}...');

      // Gọi API search thực tế
      _searchResults = await repository.searchDocuments(
        accessToken: authState.account.accessToken!,
        query: query,
        page: 1,
        limit: 20,
      );

      // Thêm vào lịch sử tìm kiếm
      _addToSearchHistory(query);

      print(
        '🔍 Search completed for "$query": ${_searchResults.length} results',
      );

      // Debug: In ra thông tin từng kết quả
      for (int i = 0; i < _searchResults.length; i++) {
        final doc = _searchResults[i];
        print('📄 Result $i: ${doc.title} (ID: ${doc.documentId})');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addToSearchHistory(String query) {
    if (query.trim().isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
  }

  void clearSearch() {
    _searchResults.clear();
    _currentQuery = '';
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _searchHistory.clear();
    notifyListeners();
  }
}
