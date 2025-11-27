import 'package:flutter_bloc/flutter_bloc.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../data/datasources/favorite_remote_data_source.dart';
import '../providers/wishlist_provider.dart'; // Keep for WishlistItem compatibility

/// WishlistBloc - Manages wishlist state
/// 
/// Uses FavoriteRepository with backend API
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final FavoriteRepository _repository;

  WishlistBloc()
      : _repository = FavoriteRepositoryImpl(
          remoteDataSource: FavoriteRemoteDataSourceImpl(),
        ),
        super(const WishlistLoading()) {
    print('❤️ WishlistBloc initialized with repository: $_repository');
    on<WishlistLoaded>(_onLoaded);
    on<WishlistItemToggled>(_onItemToggled);
    on<WishlistItemRemoved>(_onItemRemoved);
    on<WishlistCleared>(_onCleared);

    // Auto-load on initialization
    add(const WishlistLoaded());
  }

  /// Handle: Load favorites from backend
  Future<void> _onLoaded(
    WishlistLoaded event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      print('📚 WishlistBloc: Loading favorites from server...');
      final favorites = await _repository.getFavorites();
      print('📚 WishlistBloc: Received ${favorites.length} favorites');
      // Convert FavoriteItemModel to WishlistItem for compatibility
      final items = favorites.map((f) => WishlistItem(
        documentId: f.documentId,
        title: f.title,
        coverPhoto: f.coverPhoto,
      )).toList();
      final newState = WishlistData(items: items);
      print('📚 WishlistBloc: About to emit state with ${items.length} items');
      print('📚 WishlistBloc: Document IDs: ${items.map((e) => e.documentId).toList()}');
      emit(newState);
      print('📚 WishlistBloc: State emitted successfully');
      print('📚 WishlistBloc: Current state is: ${state.runtimeType}');
      if (state is WishlistData) {
        print('📚 WishlistBloc: Current state has ${(state as WishlistData).items.length} items');
      }
    } catch (e) {
      print('❌ WishlistBloc: Error loading favorites: $e');
      emit(const WishlistData(items: []));
    }
  }

  /// Handle: Toggle item in favorites
  Future<void> _onItemToggled(
    WishlistItemToggled event,
    Emitter<WishlistState> emit,
  ) async {
    if (state is! WishlistData) return;

    final currentState = state as WishlistData;
    final exists = currentState.items.any((e) => e.documentId == event.item.documentId);

    try {
      print('🔄 WishlistBloc: Toggling favorite for documentId=${event.item.documentId}, exists=$exists');
      print('🔄 WishlistBloc: Repository status: $_repository');
      
      // OPTIMISTIC UPDATE: Update UI immediately before API call
      final updatedItems = exists
          ? currentState.items.where((e) => e.documentId != event.item.documentId).toList()
          : [...currentState.items, event.item];
      
      print('🔄 WishlistBloc: Optimistic update - new count: ${updatedItems.length}');
      emit(WishlistData(items: updatedItems));
      print('🔄 WishlistBloc: Optimistic state emitted');
      
      // Then make API call
      if (exists) {
        await _repository.removeFromFavorite(event.item.documentId);
        print('✅ WishlistBloc: Removed from favorites on server');
      } else {
        await _repository.addToFavorite(event.item.documentId);
        print('✅ WishlistBloc: Added to favorites on server');
      }
      
      // Reload from server to sync and get accurate data
      print('🔄 WishlistBloc: Reloading favorites from server...');
      await _onLoaded(const WishlistLoaded(), emit);
    } catch (e, stackTrace) {
      print('❌ WishlistBloc: Error toggling favorite: $e');
      print('❌ StackTrace: $stackTrace');
      // On error, reload from server to restore accurate state
      await _onLoaded(const WishlistLoaded(), emit);
    }
  }

  /// Handle: Remove item from favorites
  Future<void> _onItemRemoved(
    WishlistItemRemoved event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      await _repository.removeFromFavorite(event.documentId);
      add(const WishlistLoaded());
    } catch (e) {
      // Handle error
    }
  }

  /// Handle: Clear favorites
  Future<void> _onCleared(
    WishlistCleared event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      await _repository.clearFavorites();
      emit(const WishlistData(items: []));
    } catch (e) {
      // Handle error
    }
  }
}
