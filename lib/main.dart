import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // File do CLI tự tạo
import 'core/theme/app_theme.dart';
import 'modules/intro/intro_screen.dart';
import 'core/services/notification_service.dart';

// Xử lý thông báo khi app ở nền hoặc bị tắt
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load môi trường
  await dotenv.load(fileName: ".env");

  try {
    // 1. Khởi tạo Firebase với Options từ CLI
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Đăng ký xử lý background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Khởi tạo Notification Service (lấy Token ở đây)
    await NotificationService.init();

    debugPrint("Firebase & Notification initialized successfully!");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farm AIOT',
      theme: AppTheme.lightTheme,
      home: const IntroScreen(),
    );
  }
}
