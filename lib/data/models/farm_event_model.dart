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

  // Convert Base64 string sang bytes để hiện ảnh
  Uint8List? get imageBytes =>
      imageBase64 != null ? base64Decode(imageBase64!) : null;

  factory FarmEvent.fromJson(Map<String, dynamic> json) {
    return FarmEvent(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      soil: (json['sensor_data']['soil'] ?? 0).toDouble(),
      temp: (json['sensor_data']['temp'] ?? 0).toDouble(),
      humi: (json['sensor_data']['humi'] ?? 0).toDouble(),
      anomalyStatus: json['inference']['anomaly']['status'] ?? "Unknown",
      plantStatus: json['inference']['plant_status']['status'] ?? "Unknown",
      imageBase64: json['image_base64'], // Chuỗi base64 thô
    );
  }
}
