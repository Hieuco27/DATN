import 'package:equatable/equatable.dart';
import '../providers/wishlist_provider.dart'; // Re-use WishlistItem model

/// States for WishlistBloc
abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

/// State: Wishlist is loading
class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

/// State: Wishlist loaded with items
class WishlistData extends WishlistState {
  final List<WishlistItem> items;

  const WishlistData({required this.items});

  /// Check if item exists (business logic giữ nguyên)
  bool contains(int documentId) {
    return items.any((e) => e.documentId == documentId);
  }

  @override
  List<Object?> get props => [items.map((e) => e.documentId).toList()];

  WishlistData copyWith({List<WishlistItem>? items}) {
    return WishlistData(items: items ?? this.items);
  }
}
