import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/datasources/cart_remote_data_source.dart';

/// CartBloc - Manages shopping cart state via Backend API
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _repository;

  CartBloc()
      : _repository = CartRepositoryImpl(
          remoteDataSource: CartRemoteDataSourceImpl(),
        ),
        super(const CartLoaded(items: [])) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQuantityUpdated>(_onQuantityUpdated);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<CartStateReset>(_onStateReset);
  }

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    try {
      final items = await _repository.getCart();
      emit(CartLoaded(items: items));
    } catch (e) {
      // Nếu lỗi (401, network...), emit empty cart để đảm bảo UI đúng
      emit(const CartLoaded(items: []));
    }
  }

  Future<void> _onItemAdded(
      CartItemAdded event, Emitter<CartState> emit) async {
    try {
      await _repository.addToCart(event.item.documentId);
      add(const CartStarted()); // Reload to sync
    } catch (e) {
    }
  }

  Future<void> _onQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    // Backend hiện tại chưa hỗ trợ update quantity trực tiếp
    // Nếu quantity <= 0 -> remove
    if (event.quantity <= 0) {
      add(CartItemRemoved(event.documentId));
    }
    // Nếu cần logic tăng giảm, có thể implement gọi add/remove nhiều lần
    // hoặc giữ logic ở client. Tạm thời chỉ reload để đảm bảo đúng data server
    add(const CartStarted());
  }

  Future<void> _onItemRemoved(
      CartItemRemoved event, Emitter<CartState> emit) async {
    try {
      await _repository.removeFromCart(event.documentId);
      add(const CartStarted());
    } catch (e) {
    }
  }

  Future<void> _onCartCleared(
      CartCleared event, Emitter<CartState> emit) async {
    try {
      await _repository.clearCart();
      emit(const CartLoaded(items: []));
    } catch (e) {
    }
  }

  /// Reset cart state locally without API call (used on logout)
  void _onStateReset(CartStateReset event, Emitter<CartState> emit) {
    emit(const CartLoaded(items: []));
  }
}
