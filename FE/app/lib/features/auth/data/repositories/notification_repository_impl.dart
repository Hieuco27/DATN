import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
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

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<NotificationListResponse> getNotifications({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) {
    return remoteDataSource.getNotifications(
      accessToken: accessToken,
      page: page,
      limit: limit,
      type: type,
      isRead: isRead,
    );
  }

  @override
  Future<NotificationDetailResponse> getNotificationDetail({
    required String accessToken,
    required int notificationId,
  }) {
    return remoteDataSource.getNotificationDetail(
      accessToken: accessToken,
      notificationId: notificationId,
    );
  }

  @override
  Future<MarkReadResponse> markAsRead({
    required String accessToken,
    required int notificationId,
  }) {
    return remoteDataSource.markAsRead(
      accessToken: accessToken,
      notificationId: notificationId,
    );
  }

  @override
  Future<MarkReadResponse> markAsUnread({
    required String accessToken,
    required int notificationId,
  }) {
    return remoteDataSource.markAsUnread(
      accessToken: accessToken,
      notificationId: notificationId,
    );
  }

  @override
  Future<MarkAllReadResponse> markAllAsRead({required String accessToken}) {
    return remoteDataSource.markAllAsRead(accessToken: accessToken);
  }
}
