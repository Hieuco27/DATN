import 'package:flutter/foundation.dart';
import '../../data/models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalMinDeposit => _items.fold(
    0,
    (sum, item) => sum + ((item.minDeposit ?? 0) * item.quantity),
  );

  int get totalMaxDeposit => _items.fold(
    0,
    (sum, item) => sum + ((item.maxDeposit ?? 0) * item.quantity),
  );

  void addItem(CartItemModel item) {
    final existingIndex = _items.indexWhere(
      (i) => i.documentId == item.documentId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(int documentId, int quantity) {
    if (quantity <= 0) {
      removeItem(documentId);
      return;
    }
    final index = _items.indexWhere((i) => i.documentId == documentId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
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
