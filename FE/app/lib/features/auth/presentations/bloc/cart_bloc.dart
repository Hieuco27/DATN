import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../data/models/cart_item_model.dart';

/// CartBloc - Manages shopping cart state
/// 
/// Replaces CartProvider with BLoC pattern
/// Business logic giữ nguyên 100%
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartLoaded(items: [])) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQuantityUpdated>(_onQuantityUpdated);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCartCleared);
  }

  /// Handle: Add item to cart
  /// Logic giữ nguyên từ CartProvider.addItem()
  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final currentState = state as CartLoaded;
    final items = List<CartItemModel>.from(currentState.items);

    final existingIndex = items.indexWhere(
      (i) => i.documentId == event.item.documentId,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + event.item.quantity,
      );
    } else {
      // Add new item
      items.add(event.item);
    }

    emit(CartLoaded(items: items));
  }

  /// Handle: Update item quantity
  /// Logic giữ nguyên từ CartProvider.updateQuantity()
  void _onQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) {
    if (event.quantity <= 0) {
      // Remove if quantity <= 0
      add(CartItemRemoved(event.documentId));
      return;
    }

    final currentState = state as CartLoaded;
    final items = List<CartItemModel>.from(currentState.items);

    final index = items.indexWhere((i) => i.documentId == event.documentId);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(CartLoaded(items: items));
    }
  }

  /// Handle: Remove item from cart
  /// Logic giữ nguyên từ CartProvider.removeItem()
  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final currentState = state as CartLoaded;
    final items = List<CartItemModel>.from(currentState.items);

    items.removeWhere((item) => item.documentId == event.documentId);

    emit(CartLoaded(items: items));
  }

  /// Handle: Clear all items
  /// Logic giữ nguyên từ CartProvider.clear()
  void _onCartCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartLoaded(items: []));
  }
}
