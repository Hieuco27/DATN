import 'package:flutter/foundation.dart';
import '../../data/models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get totalItems => _items.length;

  void addItem(CartItemModel item) {
    final existingIndex = _items.indexWhere(
      (i) => i.documentId == item.documentId,
    );
    if (existingIndex < 0) {
      _items.add(item);
      notifyListeners();
    }
  }

  void removeItem(int documentId) {
    _items.removeWhere((item) => item.documentId == documentId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool hasItem(int documentId) {
    return _items.any((item) => item.documentId == documentId);
  }

  CartItemModel? getItem(int documentId) {
    try {
      return _items.firstWhere((item) => item.documentId == documentId);
    } catch (e) {
      return null;
    }
  }
}
