import '../../data/models/favorite_item_model.dart';

abstract class FavoriteRepository {
  Future<List<FavoriteItemModel>> getFavorites();
  Future<void> addToFavorite(int documentId);
  Future<void> removeFromFavorite(int documentId);
  Future<void> clearFavorites();
}
