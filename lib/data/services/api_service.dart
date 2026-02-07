import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/farm_event_model.dart';
import '../models/prediction_model.dart';
import '../models/log_model.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.26.168.3:8000';
  static final http.Client _client = http.Client();

  // Helper method for GET requests
  static Future<dynamic> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // --- Environment API ---

  static Future<FarmEvent?> getLatestEnvironment({
    String deviceId = 'ESP32_01',
  }) async {
    try {
      final data = await _get(
        '/api/environment/latest',
        queryParams: {'device_id': deviceId},
      );
      // The API might return the object directly or null
      if (data == null) return null;
      return FarmEvent.fromJson(data);
    } catch (e) {
      print('Error fetching latest environment: $e');
      return null;
    }
  }

  static Future<List<FarmEvent>> getEnvironmentHistory({
    String deviceId = 'ESP32_01',
    String? startTime,
    String? endTime,
    String interval = '1h',
  }) async {
    try {
      final Map<String, String> params = {
        'device_id': deviceId,
        'interval': interval,
      };
      if (startTime != null) params['start_time'] = startTime;
      if (endTime != null) params['end_time'] = endTime;

      final responseData = await _get(
        '/api/environment/history',
        queryParams: params,
      );

      // History API bọc dữ liệu trong key 'data'
      final List<dynamic> dataList =
          (responseData is Map && responseData['data'] is List)
          ? responseData['data']
          : (responseData is List ? responseData : []);

      return dataList.map((json) => FarmEvent.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching environment history: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getEnvironmentStats({
    String deviceId = 'ESP32_01',
    int hours = 24,
  }) async {
    try {
      final data = await _get(
        '/api/environment/stats',
        queryParams: {'device_id': deviceId, 'hours': hours.toString()},
      );
      return data ?? {};
    } catch (e) {
      print('Error fetching environment stats: $e');
      return {};
    }
  }

  // --- Status/Logs API ---

  static Future<List<Log>> getStatusLogs({
    String deviceId = 'ESP32_01',
    String? startTime,
    String? endTime,
    int limit = 100,
  }) async {
    try {
      final Map<String, String> params = {
        'device_id': deviceId,
        'limit': limit.toString(),
      };
      if (startTime != null) params['start_time'] = startTime;
      if (endTime != null) params['end_time'] = endTime;

      final data = await _get('/api/status/logs', queryParams: params);
      if (data is List) {
        return data.map((json) => Log.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  // --- Predictions API ---
  static Future<List<Prediction>> getPredictions({
    String deviceId = 'ESP32_01',
    String? predictionType,
    int limit = 10,
  }) async {
    try {
      final Map<String, String> params = {
        'device_id': deviceId,
        'limit': limit.toString(),
      };
      if (predictionType != null) params['prediction_type'] = predictionType;

      final data = await _get('/api/predictions', queryParams: params);
      if (data is List) {
        return data.map((json) => Prediction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching predictions: $e');
      return [];
    }
  }

  // --- Device Control API ---
  static Future<bool> controlDevice(String deviceId, String action) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/devices/control'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId, 'action': action}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Control failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error controlling device: $e');
      return false;
    }
  }
}
