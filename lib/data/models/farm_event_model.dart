import 'dart:convert';
import 'dart:typed_data';

class FarmEvent {
  final DateTime timestamp;
  final double soil;
  final double temp;
  final double humi;
  final String anomalyStatus;
  final String plantStatus;
  final String? imageBase64;

  FarmEvent({
    required this.timestamp,
    required this.soil,
    required this.temp,
    required this.humi,
    required this.anomalyStatus,
    required this.plantStatus,
    this.imageBase64,
  });

  // Chuyển Base64 sang bytes
  Uint8List? get imageBytes =>
      imageBase64 != null ? base64Decode(imageBase64!) : null;

  factory FarmEvent.fromJson(Map<String, dynamic> json) {
    // Trích xuất các object con (Format cũ / Latest SSE)
    final sensorData = json['sensor_data'] as Map<String, dynamic>?;
    final inference = json['inference'] as Map<String, dynamic>?;

    // Ưu tiên đọc từ flat (Format History mới) nếu không có nested
    final tempValue = json['temperature'] ?? sensorData?['temp'] ?? 0;
    final humiValue = json['humidity'] ?? sensorData?['humi'] ?? 0;
    final soilValue = json['soil_moisture'] ?? sensorData?['soil'] ?? 0;

    // Timestamp có thể là 'time' hoặc 'timestamp'
    final timeStr = json['time'] ?? json['timestamp'];

    return FarmEvent(
      timestamp: timeStr != null ? DateTime.parse(timeStr) : DateTime.now(),
      soil: (soilValue ?? 0).toDouble(),
      temp: (tempValue ?? 0).toDouble(),
      humi: (humiValue ?? 0).toDouble(),
      anomalyStatus: inference?['anomaly']?['status'] ?? "Unknown",
      plantStatus: inference?['plant_status']?['status'] ?? "Unknown",
      imageBase64: json['image_base64'],
    );
  }
}
