import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingItem {
  final int documentId;
  final String title;
  final String coverPhoto;
  final String ebookUrl;
  final DateTime startedAt;

  ReadingItem({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
    required this.ebookUrl,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'title': title,
    'coverPhoto': coverPhoto,
    'ebookUrl': ebookUrl,
    'startedAt': startedAt.toIso8601String(),
  };

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
    documentId: json['documentId'] as int,
    title: json['title'] as String? ?? '',
    coverPhoto: json['coverPhoto'] as String? ?? '',
    ebookUrl: json['ebookUrl'] as String? ?? '',
    startedAt:
        DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class ReadingProvider with ChangeNotifier {
  static const String _storageKey = 'reading_items_v1';

  List<ReadingItem> _items = [];
  List<ReadingItem> get items => List.unmodifiable(_items);

  ReadingProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List list = json.decode(raw) as List;
      _items = list
          .map((e) => ReadingItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // sort by latest startedAt desc
      _items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  void addOrUpdate(ReadingItem item) {
    final idx = _items.indexWhere((e) => e.documentId == item.documentId);
    if (idx >= 0) {
      _items.removeAt(idx);
    }
    _items.insert(0, item);
    _persist();
    notifyListeners();
  }

  void remove(int documentId) {
    _items.removeWhere((e) => e.documentId == documentId);
    _persist();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }
}
