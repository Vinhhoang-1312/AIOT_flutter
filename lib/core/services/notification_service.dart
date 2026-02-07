import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      // 1. Xin quyền thông báo (Trên Android 13+ sẽ hiện thông báo xin quyền)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Người dùng đã cấp quyền thông báo.');
      }

      // 2. Lấy FCM Token để gửi từ Backend
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("\n================ FCM TOKEN ================");
        debugPrint(token);
        debugPrint("===========================================\n");
      }

      // 3. Cấu hình khởi tạo Local Notifications cho Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint("Người dùng đã nhấn vào thông báo: ${details.payload}");
        },
      );

      // 4. Lắng nghe tin nhắn khi App đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Nhận tin nhắn Foreground: ${message.notification?.title}");
        _showNotification(message);
      });
    } catch (e) {
      debugPrint("Lỗi khởi tạo NotificationService: $e");
    }
  }

  // Hàm hiển thị thông báo popup trên Android
  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'farm_channel_id', // ID phải khớp với cấu hình trong Firebase Console nếu có
            'Farm Notifications',
            channelDescription: 'Cảnh báo từ hệ thống vườn thông minh',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            // Thêm âm thanh và rung để gây chú ý cho cảnh báo vườn
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
