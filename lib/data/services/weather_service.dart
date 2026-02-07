import 'dart:convert';
import 'package:http/http.dart' as http;

class City {
  final String name;
  final double lat;
  final double lon;

  const City({required this.name, required this.lat, required this.lon});
}

class WeatherService {
  // Predefined cities
  static const List<City> cities = [
    City(name: "Đà Nẵng", lat: 16.0471, lon: 108.2068),
    City(name: "Hà Nội", lat: 21.0285, lon: 105.8542),
    City(name: "Hồ Chí Minh", lat: 10.8231, lon: 106.6297),
    City(name: "Hải Phòng", lat: 20.8449, lon: 106.6881),
    City(name: "Cần Thơ", lat: 10.0452, lon: 105.7469),
    City(name: "Huế", lat: 16.4637, lon: 107.5909),
    City(name: "Nha Trang", lat: 12.2388, lon: 109.1967),
    City(name: "Đà Lạt", lat: 11.9404, lon: 108.4583),
  ];

  // Default Da Nang coordinates
  static const double defaultLat = 16.0471;
  static const double defaultLon = 108.2068;

  Future<Map<String, dynamic>?> getWeather({double? lat, double? lon}) async {
    final latitude = lat ?? defaultLat;
    final longitude = lon ?? defaultLon;

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,is_day,rain,showers,weather_code,cloud_cover&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching weather: $e");
      return null;
    }
  }

  String getWeatherDescription(int code) {
    // WMO Weather interpretation codes (WW)
    if (code == 0) return "Trời quang";
    if (code == 1 || code == 2 || code == 3) return "Có mây";
    if (code == 45 || code == 48) return "Sương mù";
    if (code >= 51 && code <= 55) return "Mưa phùn";
    if (code >= 61 && code <= 65) return "Mưa rào";
    if (code >= 71 && code <= 77) return "Tuyết rơi";
    if (code >= 80 && code <= 82) return "Mưa to";
    if (code >= 95) return "Dông bão";
    return "Không rõ";
  }

  // Estimate Lux or Light condition based on Day/Night and Cloud/Weather
  String getLightCondition(Map<String, dynamic> current) {
    final isDay = current['is_day'] == 1;
    final cloudCover = current['cloud_cover'] as num;

    if (!isDay) return "Ban đêm";

    if (cloudCover < 20) return "Nắng gắt";
    if (cloudCover < 50) return "Nắng nhẹ";
    if (cloudCover < 85) return "Nhiều mây";
    return "Âm u";
  }
}
