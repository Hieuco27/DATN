import 'package:equatable/equatable.dart';
import '../providers/wishlist_provider.dart'; // Re-use WishlistItem model

/// Events for WishlistBloc
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load wishlist from storage (on init)
class WishlistLoaded extends WishlistEvent {
  const WishlistLoaded();
}

/// Event: Toggle item in wishlist
class WishlistItemToggled extends WishlistEvent {
  final WishlistItem item;

  const WishlistItemToggled(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event: Remove item from wishlist
class WishlistItemRemoved extends WishlistEvent {
  final int documentId;

  const WishlistItemRemoved(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Event: Clear wishlist
class WishlistCleared extends WishlistEvent {
  const WishlistCleared();
}
