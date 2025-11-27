import '../../data/models/cart_item_model.dart';

abstract class CartRepository {
  Future<List<CartItemModel>> getCart();
  Future<void> addToCart(int documentId);
  Future<void> removeFromCart(int documentId);
  Future<void> clearCart();
}
