import 'package:dio/dio.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/core/utils/app_logger.dart';

class TokenInterceptor extends Interceptor {
  final LocalStorageDataSource localStorage;
  final Dio dio;

  // Flag để tránh concurrent token refresh
  bool _isRefreshing = false;

  // Queue để lưu các requests đang chờ token refresh
  final List<_PendingRequest> _requestQueue = [];

  // Max số lần retry để tránh infinite loop
  static const int _maxRetryCount = 1;
  static const String _refreshTokenPath = '/auth/refresh-token';

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
    // QUAN TRỌNG: Không xử lý 401 nếu request là refresh-token API
    // Tránh infinite loop khi refresh token cũng return 401
    if (err.requestOptions.path.contains(_refreshTokenPath)) {
      log.w('Refresh token API failed with 401, not retrying', 'TokenInterceptor');
      handler.next(err);
      return;
    }

    // Nếu lỗi 401 (Unauthorized), thử refresh token
    if (err.response?.statusCode == 401) {
      // Kiểm tra retry count để tránh infinite loop
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      if (retryCount >= _maxRetryCount) {
        log.w('Max retry count reached ($retryCount), not retrying', 'TokenInterceptor');
        handler.next(err);
        return;
      }

      // Nếu đang refresh, queue request này
      if (_isRefreshing) {
        log.d('Token refresh in progress, queueing request', 'TokenInterceptor');
        _requestQueue.add(_PendingRequest(
          requestOptions: err.requestOptions,
          handler: handler,
          retryCount: retryCount,
        ));
        return;
      }

      // Bắt đầu refresh token
      _isRefreshing = true;
      log.i('Starting token refresh...', 'TokenInterceptor');

      try {
        final newToken = await _refreshToken();
        
        if (newToken != null) {
          log.i('Token refresh successful', 'TokenInterceptor');
          
          // Retry request gốc với token mới
          try {
            final response = await _retryRequest(err.requestOptions, retryCount + 1);
            handler.resolve(response);
          } catch (e) {
            log.e('Failed to retry original request', e, 'TokenInterceptor');
            handler.next(err);
          }

          // Retry tất cả queued requests
          await _processQueuedRequests();
        } else {
          log.w('Token refresh failed, rejecting all requests', 'TokenInterceptor');
          handler.next(err);
          _rejectQueuedRequests();
        }
      } catch (e) {
        log.e('Token refresh error', e, 'TokenInterceptor');
        handler.next(err);
        _rejectQueuedRequests();
      } finally {
        _isRefreshing = false;
        log.d('Token refresh process completed', 'TokenInterceptor');
      }

      return;
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await localStorage.getRefreshToken();
      if (refreshToken == null) {
        log.w('No refresh token available', 'TokenInterceptor');
        return null;
      }

      log.d('Calling refresh token API...', 'TokenInterceptor');

      // Call API refresh token
      final response = await dio.post(
        _refreshTokenPath,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data == null) {
          log.w('Refresh token response has no data', 'TokenInterceptor');
          return null;
        }

        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken == null || newRefreshToken == null) {
          log.w('Refresh token response missing tokens', 'TokenInterceptor');
          return null;
        }

        // Lưu tokens mới
        await localStorage.saveTokens(newAccessToken, newRefreshToken);
        log.d('New tokens saved successfully', 'TokenInterceptor');

        return newAccessToken;
      }
      
      log.w('Refresh token API returned status ${response.statusCode}', 'TokenInterceptor');
      return null;
    } catch (e) {
      log.e('Refresh token failed', e, 'TokenInterceptor');
      return null;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    int newRetryCount,
  ) async {
    final token = await localStorage.getAccessToken();

    log.d('Retrying request: ${requestOptions.path} (retry: $newRetryCount)', 'TokenInterceptor');

    // Tăng retry count trong extra để track
    final updatedExtra = {...requestOptions.extra, 'retryCount': newRetryCount};

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
        extra: updatedExtra,
      ),
    );
  }

  /// Xử lý tất cả requests đang trong queue
  Future<void> _processQueuedRequests() async {
    if (_requestQueue.isEmpty) return;

    log.i('Processing ${_requestQueue.length} queued requests', 'TokenInterceptor');

    // Process all queued requests
    for (final pending in _requestQueue) {
      try {
        final response = await _retryRequest(
          pending.requestOptions,
          pending.retryCount + 1,
        );
        pending.handler.resolve(response);
      } catch (e) {
        log.e('Failed to retry queued request', e, 'TokenInterceptor');
        pending.handler.next(
          DioException(
            requestOptions: pending.requestOptions,
            error: e,
          ),
        );
      }
    }

    _requestQueue.clear();
  }

  /// Reject tất cả requests trong queue khi refresh thất bại
  void _rejectQueuedRequests() {
    if (_requestQueue.isEmpty) return;

    log.w('Rejecting ${_requestQueue.length} queued requests', 'TokenInterceptor');

    for (final pending in _requestQueue) {
      pending.handler.next(
        DioException(
          requestOptions: pending.requestOptions,
          error: 'Token refresh failed',
          response: Response(
            requestOptions: pending.requestOptions,
            statusCode: 401,
          ),
        ),
      );
    }

    _requestQueue.clear();
  }
}

/// Helper class để lưu pending requests trong queue
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  final int retryCount;

  _PendingRequest({
    required this.requestOptions,
    required this.handler,
    required this.retryCount,
  });
}
