import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CartItemModel>> getCart() async {
    return await remoteDataSource.getCart();
  }

  @override
  Future<void> addToCart(int documentId) async {
    await remoteDataSource.addToCart(documentId);
  }

  @override
  Future<void> removeFromCart(int documentId) async {
    await remoteDataSource.removeFromCart(documentId);
  }

  @override
  Future<void> clearCart() async {
    await remoteDataSource.clearCart();
  }
}
