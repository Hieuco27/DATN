// FE/app/lib/features/auth/data/datasources/loan_remote_data_source.dart
import 'package:dio/dio.dart';
import 'package:book_tech/core/network/dio_client.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/data/models/loan_history_models.dart';

abstract class LoanRemoteDataSource {
  Future<LoanResponse> getMyLoans({required int page, required int limit});
}

class LoanRemoteDataSourceImpl implements LoanRemoteDataSource {
  final Dio dio;
  LoanRemoteDataSourceImpl({required this.dio});

  factory LoanRemoteDataSourceImpl.create(LocalStorageDataSource local) {
    return LoanRemoteDataSourceImpl(dio: DioClient.createDio(local));
  }

  @override
  Future<LoanResponse> getMyLoans({
    required int page,
    required int limit,
  }) async {
    final res = await dio.get(
      '/loans/reader/loans/my',
      queryParameters: {'page': page, 'limit': limit},
    );
    return LoanResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
