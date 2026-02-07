import 'package:flutter/material.dart';
import '../../data/services/weather_service.dart';

class CitySelectionScreen extends StatelessWidget {
  const CitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Chọn Tỉnh/Thành phố",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: WeatherService.cities.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final city = WeatherService.cities[index];
          return ListTile(
            title: Text(
              city.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white54,
            ),
            onTap: () {
              Navigator.pop(context, city);
            },
          );
        },
      ),
    );
  }
}
