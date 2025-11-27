import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';

/// States for CartBloc
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// State: Cart with items
class CartLoaded extends CartState {
  final List<CartItemModel> items;

  const CartLoaded({required this.items});

  

  bool hasItem(int documentId) {
    return items.any((item) => item.documentId == documentId);
  }

  CartItemModel? getItem(int documentId) {
    try {
      return items.firstWhere((item) => item.documentId == documentId);
    } catch (e) {
      return null;
    }
  }

  /// For state comparison
  @override
  List<Object?> get props => [items];

  /// CopyWith for immutable updates
  CartLoaded copyWith({List<CartItemModel>? items}) {
    return CartLoaded(items: items ?? this.items);
  }
}
