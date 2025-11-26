import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../network/api_config.dart';

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 [Background] Message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Có thể xử lý logic background ở đây (lưu vào DB local, etc.)
  // Nhưng không nên show UI - hệ thống sẽ tự hiển thị notification
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream để các widget có thể lắng nghe thông báo
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationReceived =>
      _notificationStreamController.stream;

  /// Khởi tạo Firebase Messaging và Local Notifications
  Future<void> initialize() async {
    try {
      print('🔔 [NotificationService] Initializing...');

      // 1. Xin quyền thông báo
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [NotificationService] Permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ [NotificationService] Provisional permission granted');
      } else {
        print('❌ [NotificationService] Permission denied');
        return;
      }

      // 2. Cấu hình Local Notifications (hiển thị khi app foreground)
      await _initializeLocalNotifications();

      // 3. Lấy FCM Token
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 [NotificationService] FCM Token: $_fcmToken');

      // 4. Lắng nghe khi token thay đổi
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 [NotificationService] Token refreshed: $newToken');
        _fcmToken = newToken;
        // Gọi API cập nhật token mới lên server
        _updateTokenOnServer(newToken);
      });

      // 5. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 6. Lắng nghe thông báo khi app đang mở (foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 7. Xử lý khi người dùng bấm vào thông báo (app từ background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 8. Kiểm tra nếu app được mở từ thông báo (khi terminated)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📬 [NotificationService] App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      print('✅ [NotificationService] Initialization completed');
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Initialization failed: $e');
      print(stackTrace);
    }
  }

  /// Cấu hình Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào local notification
        print('📱 [Local Notification] Tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _notificationStreamController.add(data);
          } catch (e) {
            print('⚠️ Failed to parse notification payload: $e');
          }
        }
      },
    );

    print('✅ [Local Notifications] Initialized');
  }

  /// Xử lý thông báo khi app đang mở (foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 [Foreground] Message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Hiển thị local notification
    _showLocalNotification(message);

    // Emit vào stream để các widget có thể lắng nghe
    _notificationStreamController.add({
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      ...message.data,
    });
  }

  /// Hiển thị local notification (khi app foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel', // Channel ID
      'Default Notifications', // Channel name
      channelDescription: 'Thông báo từ Book Tech',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode, // Notification ID
      message.notification?.title ?? 'Thông báo mới',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );

    print('✅ [Local Notification] Displayed');
  }

  /// Xử lý khi người dùng bấm vào thông báo (từ background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 [Notification Tap] User tapped on notification');
    print('   Data: ${message.data}');

    // Emit vào stream
    _notificationStreamController.add({
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'tapped': true, // Đánh dấu là notification được bấm
      ...message.data,
    });

    // TODO: Navigate to specific screen dựa vào message.data
    // Ví dụ: nếu data['type'] == 'RESERVATION_APPROVED', navigate to loan detail
    // Bạn có thể dùng Navigator hoặc routing system của bạn
  }

  /// Gọi API lưu token lên server
  Future<void> registerTokenOnServer(String accessToken) async {
    if (_fcmToken == null) {
      print('⚠️ [NotificationService] No FCM token to register');
      return;
    }

    await _updateTokenOnServer(_fcmToken!, accessToken: accessToken);
  }

  /// Cập nhật token lên server
  Future<void> _updateTokenOnServer(String token, {String? accessToken}) async {
    try {
      // Nếu không có accessToken, lấy từ secure storage
      String? authToken = accessToken;
      if (authToken == null) {
        // Bạn có thể lấy từ SecureStorageService hoặc cache
        // Tạm thời bỏ qua nếu không có token
        print('⚠️ [NotificationService] No access token to register FCM token');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ));

      final response = await dio.post(
        '/fcm/register',
        data: {'fcmToken': token},
      );

      if (response.statusCode == 200) {
        print('✅ [NotificationService] Token registered on server');
      } else {
        print('⚠️ [NotificationService] Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NotificationService] Error registering token: $e');
    }
  }

  /// Hủy đăng ký token khi logout
  Future<void> unregisterTokenOnServer(String accessToken) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ));

      final response = await dio.post('/fcm/unregister');

      if (response.statusCode == 200) {
        print('✅ [NotificationService] Token unregistered from server');
      } else {
        print('⚠️ [NotificationService] Failed to unregister token');
      }
    } catch (e) {
      print('❌ [NotificationService] Error unregistering token: $e');
    }
  }

  /// Dispose stream
  void dispose() {
    _notificationStreamController.close();
  }
}
