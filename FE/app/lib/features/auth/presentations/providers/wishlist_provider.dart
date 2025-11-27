import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistItem {
  final int documentId;
  final String title;
  final String coverPhoto;

  WishlistItem({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
  });

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'title': title,
    'coverPhoto': coverPhoto,
  };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    documentId: json['documentId'] as int,
    title: json['title'] as String? ?? '',
    coverPhoto: json['coverPhoto'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItem &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId;

  @override
  int get hashCode => documentId.hashCode;
}

class WishlistProvider with ChangeNotifier {
  static const String _storageKey = 'wishlist_items_v1';

  List<WishlistItem> _items = [];
  List<WishlistItem> get items => List.unmodifiable(_items);

  WishlistProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List list = json.decode(raw) as List;
      _items = list
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  bool contains(int documentId) {
    return _items.any((e) => e.documentId == documentId);
  }

  void toggle(WishlistItem item) {
    final idx = _items.indexWhere((e) => e.documentId == item.documentId);
    if (idx >= 0) {
      _items.removeAt(idx);
    } else {
      _items.insert(0, item);
    }
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
