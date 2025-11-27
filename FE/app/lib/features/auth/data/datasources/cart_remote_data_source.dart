import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cart_item_model.dart';
import 'local_storage_data_source.dart';

abstract class CartRemoteDataSource {
  Future<List<CartItemModel>> getCart();
  Future<void> addToCart(int documentId);
  Future<void> removeFromCart(int documentId);
  Future<void> clearCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final Dio dio;

  CartRemoteDataSourceImpl({Dio? dio})
      : dio = dio ?? DioClient.createDio(LocalStorageDataSourceImpl());

  @override
  Future<List<CartItemModel>> getCart() async {
    try {
      final response = await dio.get('/cart');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CartItemModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải giỏ hàng: $e');
    }
  }

  @override
  Future<void> addToCart(int documentId) async {
    try {
      await dio.post('/cart/add', data: {'documentId': documentId});
    } catch (e) {
      throw Exception('Lỗi thêm vào giỏ: $e');
    }
  }

  @override
  Future<void> removeFromCart(int documentId) async {
    try {
      await dio.delete('/cart/$documentId');
    } catch (e) {
      throw Exception('Lỗi xóa khỏi giỏ: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await dio.delete('/cart');
    } catch (e) {
      throw Exception('Lỗi xóa giỏ hàng: $e');
    }
  }
}
