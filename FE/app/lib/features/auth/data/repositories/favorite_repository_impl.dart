import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_data_source.dart';
import '../models/favorite_item_model.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FavoriteItemModel>> getFavorites() async {
    return await remoteDataSource.getFavorites();
  }

  @override
  Future<void> addToFavorite(int documentId) async {
    await remoteDataSource.addToFavorite(documentId);
  }

  @override
  Future<void> removeFromFavorite(int documentId) async {
    await remoteDataSource.removeFromFavorite(documentId);
  }

  @override
  Future<void> clearFavorites() async {
    await remoteDataSource.clearFavorites();
  }
}
