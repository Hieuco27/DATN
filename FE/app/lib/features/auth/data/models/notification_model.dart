class NotificationModel {
  final int notificationID;
  final int readerId;
  final String type; // SYSTEM, LOAN_PENDING, LOAN_APPROVED, etc.
  final String title;
  final String content;
  final bool isRead;
  final String priority;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationID,
    required this.readerId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.priority,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationID: json['notificationID'] as int,
      readerId: json['readerId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isRead: (json['isRead'] as int? ?? 0) == 1,
      priority: json['priority'] as String,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationID': notificationID,
      'readerId': readerId,
      'type': type,
      'title': title,
      'content': content,
      'isRead': isRead ? 1 : 0,
      'readAt': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? notificationID,
    int? readerId,
    String? type,
    String? title,
    String? content,
    bool? isRead,
    String? priority,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationID: notificationID ?? this.notificationID,
      readerId: readerId ?? this.readerId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationListResponse {
  final bool success;
  final PaginationInfo? pagination;
  final List<NotificationModel> data;

  NotificationListResponse({
    required this.success,
    this.pagination,
    required this.data,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      success: json['success'] == true,
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NotificationDetailResponse {
  final bool success;
  final NotificationModel data;

  NotificationDetailResponse({required this.success, required this.data});

  factory NotificationDetailResponse.fromJson(Map<String, dynamic> json) {
    return NotificationDetailResponse(
      success: json['success'] == true,
      data: NotificationModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class MarkReadResponse {
  final bool success;
  final int notificationID;
  final bool isRead;
  final DateTime? readAt;

  MarkReadResponse({
    required this.success,
    required this.notificationID,
    required this.isRead,
    this.readAt,
  });

  factory MarkReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkReadResponse(
      success: json['success'] == true,
      notificationID: json['data']['notificationID'] as int,
      isRead: (json['data']['isRead'] as int) == 1,
      readAt: json['data']['readAt'] != null
          ? DateTime.parse(json['data']['readAt'] as String)
          : null,
    );
  }
}

class MarkAllReadResponse {
  final bool success;
  final int updated;

  MarkAllReadResponse({required this.success, required this.updated});

  factory MarkAllReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkAllReadResponse(
      success: json['success'] == true,
      updated: json['updated'] as int,
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
