import 'package:dio/dio.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationListResponse> getNotifications({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  Future<NotificationDetailResponse> getNotificationDetail({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkReadResponse> markAsRead({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkReadResponse> markAsUnread({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkAllReadResponse> markAllAsRead({required String accessToken});
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 60);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeoutDuration,
      receiveTimeout: timeoutDuration,
      sendTimeout: timeoutDuration,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<NotificationListResponse> getNotifications({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (isRead != null) {
        queryParams['isRead'] = isRead ? 1 : 0;
      }

      final response = await dio.get(
        '/notifications',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return NotificationListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting notifications: $e');
    }
  }

  @override
  Future<NotificationDetailResponse> getNotificationDetail({
    required String accessToken,
    required int notificationId,
  }) async {
    try {
      final response = await dio.get(
        '/notifications/$notificationId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return NotificationDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Failed to get notification detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting notification detail: $e');
    }
  }

  @override
  Future<MarkReadResponse> markAsRead({
    required String accessToken,
    required int notificationId,
  }) async {
    try {
      final response = await dio.put(
        '/notifications/$notificationId/mark-read',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return MarkReadResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking as read: $e');
    }
  }

  @override
  Future<MarkReadResponse> markAsUnread({
    required String accessToken,
    required int notificationId,
  }) async {
    try {
      final response = await dio.put(
        '/notifications/$notificationId/mark-unread',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return MarkReadResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to mark as unread: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking as unread: $e');
    }
  }

  @override
  Future<MarkAllReadResponse> markAllAsRead({
    required String accessToken,
  }) async {
    try {
      // Try the correct endpoint path
      final response = await dio.put(
        '/notifications/mark-all-read',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      

      if (response.statusCode == 200) {
        return MarkAllReadResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Chức năng "Đọc tất cả" chưa được hỗ trợ bởi server. Vui lòng đánh dấu từng thông báo.',
        );
      }
      throw Exception('Error marking all as read: ${e.message}');
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }
}
