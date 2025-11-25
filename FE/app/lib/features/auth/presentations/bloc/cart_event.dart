import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';

/// Events for CartBloc
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Add item to cart
class CartItemAdded extends CartEvent {
  final CartItemModel item;

  const CartItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event: Update item quantity
class CartItemQuantityUpdated extends CartEvent {
  final int documentId;
  final int quantity;

  const CartItemQuantityUpdated({
    required this.documentId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [documentId, quantity];
}

/// Event: Remove item from cart
class CartItemRemoved extends CartEvent {
  final int documentId;

  const CartItemRemoved(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Event: Clear all items
class CartCleared extends CartEvent {
  const CartCleared();
}
