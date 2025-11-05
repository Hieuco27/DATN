import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SearchProvider with ChangeNotifier {
  final DocumentRepository repository;
  SearchProvider(this.repository);

  bool _isLoading = false;
  String? _error;
  List<DocumentEntity> _searchResults = [];
  String _currentQuery = '';
  List<String> _searchHistory = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DocumentEntity> get searchResults => _searchResults;
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

      // Gọi API với từ đầu tiên đã bỏ dấu để server trả phạm vi rộng
      final normalizedFull = _normalizeText(query);
      final firstToken = normalizedFull.split(' ').first;
      if (firstToken.isEmpty) {
        clearSearch();
        return;
      }
      List<DocumentEntity> fetchedResults = await repository.searchDocuments(
        accessToken: authState.account.accessToken!,
        query: firstToken,
        page: 1,
        limit: 20,
      );

      // Lọc theo tiêu đề (accent-insensitive, case-insensitive) và ưu tiên bắt đầu bằng từ khóa
      final normalizedQuery = _normalizeText(_currentQuery);
      final filtered = fetchedResults
          .where((doc) => _normalizeText(doc.title).contains(normalizedQuery))
          .toList();

      filtered.sort((a, b) {
        final aTitle = _normalizeText(a.title);
        final bTitle = _normalizeText(b.title);
        final aStarts = aTitle.startsWith(normalizedQuery);
        final bStarts = bTitle.startsWith(normalizedQuery);
        if (aStarts == bStarts) {
          return aTitle.compareTo(bTitle);
        }
        return bStarts ? 1 : -1; // true trước false
      });

      _searchResults = filtered;

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

  String _normalizeText(String input) {
    String s = input.toLowerCase().trim();
    // Chuẩn hóa khoảng trắng
    s = s.replaceAll(RegExp(r"\s+"), ' ');
    // Loại bỏ dấu tiếng Việt phổ biến
    const Map<String, String> map = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    map.forEach((non, accented) {
      s = s.replaceAll(
        RegExp('[' + accented + accented.toUpperCase() + ']'),
        non,
      );
    });
    return s;
  }
}
