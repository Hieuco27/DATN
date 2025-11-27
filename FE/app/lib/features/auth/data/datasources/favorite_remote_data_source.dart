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
      print('📡 API: GET /favorite');
      final response = await dio.get('/favorite');
      print('📡 API Response: ${response.statusCode}');
      print('📡 API Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final items = data.map((json) => FavoriteItemModel.fromJson(json)).toList();
        print('✅ Parsed ${items.length} favorites');
        return items;
      }
      return [];
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Lỗi tải danh sách yêu thích: $e');
    }
  }

  @override
  Future<void> addToFavorite(int documentId) async {
    try {
      print('📡 API: POST /favorite/add with documentId=$documentId');
      final response = await dio.post('/favorite/add', data: {'documentId': documentId});
      print('✅ API Response: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Lỗi thêm vào yêu thích: $e');
    }
  }

  @override
  Future<void> removeFromFavorite(int documentId) async {
    try {
      print('📡 API: DELETE /favorite/$documentId');
      final response = await dio.delete('/favorite/$documentId');
      print('✅ API Response: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('❌ API Error: $e');
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
