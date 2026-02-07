// lib/modules/controls/pump_control_screen.dart
import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';

class PumpControlScreen extends StatefulWidget {
  const PumpControlScreen({super.key});

  @override
  State<PumpControlScreen> createState() => _PumpControlScreenState();
}

class _PumpControlScreenState extends State<PumpControlScreen> {
  bool isAutoMode = true; // Mặc định là tự động
  bool isPumpOn = false; // Trạng thái máy bơm
  bool isLoading = false; // Trạng thái đang gửi lệnh

  Future<void> _togglePump() async {
    setState(() {
      isLoading = true;
    });

    final action = isPumpOn ? "pump_off" : "pump_on";
    final success = await ApiService.controlDevice("ESP32_01", action);

    if (mounted) {
      setState(() {
        isLoading = false;
        if (success) {
          isPumpOn = !isPumpOn;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Gửi lệnh ${isPumpOn ? 'BẬT' : 'TẮT'} thành công"
                : "Gửi lệnh thất bại. Kiểm tra backend.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Điều Khiển Máy Bơm",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ trạng thái tổng quan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2630),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                    color: isPumpOn ? Colors.blue : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPumpOn ? "MÁY BƠM ĐANG CHẠY" : "MÁY BƠM ĐANG TẮT",
                        style: TextStyle(
                          color: isPumpOn ? Colors.blue : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isAutoMode
                            ? "Điều khiển bởi AI"
                            : "Điều khiển thủ công",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Switch chọn chế độ
            SwitchListTile(
              title: const Text(
                "Chế độ Tự động (AI)",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: const Text(
                "Hệ thống tự quyết định tưới dựa trên độ ẩm",
                style: TextStyle(color: Colors.grey),
              ),
              value: isAutoMode,
              activeColor: const Color(0xFF00E676),
              onChanged: (val) async {
                setState(() {
                  isAutoMode = val;
                });
                // Nếu bật auto, gửi lệnh tắt máy bơm để AI quản lý
                if (isAutoMode && isPumpOn) {
                  await _togglePump();
                }
              },
            ),

            const Divider(color: Colors.white24, height: 40),

            // Nút Bật/Tắt thủ công
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: (isAutoMode || isLoading)
                          ? null // Không cho bấm nếu đang Auto hoặc đang load
                          : _togglePump,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAutoMode
                              ? Colors.grey.withOpacity(0.1)
                              : (isPumpOn
                                    ? Colors.blueAccent
                                    : const Color(0xFF2A2A2A)),
                          boxShadow: isPumpOn
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: isAutoMode
                                ? Colors.transparent
                                : (isPumpOn ? Colors.blue : Colors.white24),
                            width: 2,
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new,
                                size: 80,
                                color: isAutoMode ? Colors.grey : Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAutoMode
                          ? "Vui lòng tắt chế độ Auto để điều khiển"
                          : "Nhấn để BẬT / TẮT",
                      style: TextStyle(
                        color: isAutoMode ? Colors.redAccent : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
