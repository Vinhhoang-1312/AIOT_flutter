import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông Tin Dự Án")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          // FIX TẠI ĐÂY: Dùng child: Column thay vì children trực tiếp
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái cho đẹp
            children: [
              _buildSection(
                "Mục tiêu nghiên cứu",
                "Thiết kế hệ thống tưới tiêu thông minh cân bằng chi phí, năng lượng và trí tuệ dự đoán AI.",
              ),
              _buildSection(
                "Kiến trúc hệ thống",
                "Sử dụng ESP32 & LoRa để thu thập dữ liệu, MQTT truyền tin và AI LSTM để dự báo.",
              ),
              const SizedBox(height: 20),
              const Text(
                "Đội ngũ phát triển - Group 4",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 12),
              _buildMember("Vĩnh Hoàng", "Hardware & Flutter Mobile App"),
              _buildMember("Anh Kỳ", "Hardware & Flutter Mobile App"),
              _buildMember("Đức Tín", "Backend Server & AI Data"),
              _buildMember("San", "Backend Server & AI Data"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity, // Đảm bảo khung rộng hết màn hình
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildMember(String name, String role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.greenAccent,
          child: Icon(Icons.person, color: Colors.black),
        ),
        title: Text(name),
        subtitle: Text(role),
      ),
    );
  }
}
