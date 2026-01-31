// lib/modules/home/log_screen.dart
import 'package:flutter/material.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập từ Backend
    final List<Map<String, dynamic>> logs = [
      {
        "time": "14:30",
        "title": "Phân tích đất",
        "msg": "Độ ẩm đất đạt 65%. Không cần tưới nước cho đến 18:00.",
        "type": "info",
      },
      {
        "time": "12:15",
        "title": "Cảnh báo nhiệt độ",
        "msg":
            "Nhiệt độ vườn tăng lên 36°C. Hệ thống đã kích hoạt phun sương 5 phút.",
        "type": "warning",
      },
      {
        "time": "08:00",
        "title": "Báo cáo sáng",
        "msg": "Hôm nay dự báo không mưa. Hệ thống lên lịch tưới lúc 17:30.",
        "type": "info",
      },
      {
        "time": "06:00",
        "title": "Hệ thống",
        "msg": "Thiết bị ESP32 đã kết nối lại thành công.",
        "type": "success",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Nhật Ký Hoạt Động",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogItem(log);
        },
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    Color iconColor;
    IconData iconData;

    switch (log['type']) {
      case 'warning':
        iconColor = Colors.orange;
        iconData = Icons.warning_amber_rounded;
        break;
      case 'success':
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        break;
      default:
        iconColor = Colors.blue;
        iconData = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: iconColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                log['time'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Icon(iconData, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log['msg'],
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
