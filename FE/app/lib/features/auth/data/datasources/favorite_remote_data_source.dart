import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/favorite_item_model.dart';
import 'local_storage_data_source.dart';

abstract class FavoriteRemoteDataSource {
  Future<List<FavoriteItemModel>> getFavorites();
  Future<void> addToFavorite(int documentId);
  Future<void> removeFromFavorite(int documentId);
  Future<void> clearFavorites();
}

class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final Dio dio;

  FavoriteRemoteDataSourceImpl({Dio? dio})
      : dio = dio ?? DioClient.createDio(LocalStorageDataSourceImpl());

  @override
  Future<List<FavoriteItemModel>> getFavorites() async {
    try {
      final response = await dio.get('/favorite');
   
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final items = data.map((json) => FavoriteItemModel.fromJson(json)).toList();
        return items;
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách yêu thích: $e');
    }
  }

  @override
  Future<void> addToFavorite(int documentId) async {
    try {
      print('📡 API: POST /favorite/add with documentId=$documentId');
      await dio.post('/favorite/add', data: {'documentId': documentId});
      print('✅ Added to favorites successfully');
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Lỗi thêm vào yêu thích: $e');
    }
  }

  @override
  Future<void> removeFromFavorite(int documentId) async {
    try {
      await dio.delete('/favorite/$documentId');
    } catch (e) {
      throw Exception('Lỗi xóa khỏi yêu thích: $e');
    }
  }

  @override
  Future<void> clearFavorites() async {
    try {
      await dio.delete('/favorite');
    } catch (e) {
      throw Exception('Lỗi xóa danh sách yêu thích: $e');
    }
  }
}
