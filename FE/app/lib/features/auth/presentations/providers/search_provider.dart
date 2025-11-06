import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SearchProvider with ChangeNotifier {
  final DocumentRepository repository;
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 5;

  SearchProvider(this.repository) {
    _loadSearchHistory();
  }

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

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey);
      if (historyJson != null) {
        _searchHistory = historyJson;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  // Public method để reload lịch sử từ SharedPreferences
  Future<void> reloadSearchHistory() async {
    await _loadSearchHistory();
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    // Xóa query cũ nếu đã tồn tại (để đưa lên đầu)
    _searchHistory.remove(trimmedQuery);

    // Thêm vào đầu danh sách
    _searchHistory.insert(0, trimmedQuery);

    // Giới hạn tối đa 5 item
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }

    // Lưu vào SharedPreferences
    _saveSearchHistory();
    notifyListeners();
  }

  void clearSearch() {
    _searchResults.clear();
    _currentQuery = '';
    _error = null;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _searchHistory.clear();
    notifyListeners();

    // Xóa khỏi SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
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
