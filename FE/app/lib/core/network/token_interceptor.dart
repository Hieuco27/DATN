import 'package:dio/dio.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';

class TokenInterceptor extends Interceptor {
  final LocalStorageDataSource localStorage;
  final Dio dio;

  TokenInterceptor({required this.localStorage, required this.dio});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Thêm access token vào header
    final token = await localStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Nếu lỗi 401 (Unauthorized), thử refresh token
    if (err.response?.statusCode == 401) {
      try {
        // Refresh token
        final newToken = await _refreshToken();
        if (newToken != null) {
          // Retry request với token mới
          final response = await _retryRequest(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {}
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await localStorage.getRefreshToken();
      if (refreshToken == null) return null;

      // Call API refresh token
      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['data']['accessToken'];
        final newRefreshToken = response.data['data']['refreshToken'];

        // Lưu tokens mới
        await localStorage.saveTokens(newAccessToken, newRefreshToken);

        return newAccessToken;
      }
    } catch (e) {}
    return null;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await localStorage.getAccessToken();

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
      ),
    );
  }
}
