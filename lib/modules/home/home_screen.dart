import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/farm_event_model.dart';
import '../../data/services/weather_service.dart';
import '../../widgets/sensor_card.dart';
import '../camera/camera_screen.dart';
import '../controls/pump_control_screen.dart';
import 'city_selection_screen.dart';
import 'log_screen.dart';
import 'sensor_dashboard_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FarmEvent> _eventHistory = [];
  FarmEvent? _latestEvent;

  final WeatherService _weatherService = WeatherService();
  City _selectedCity = WeatherService.cities[0]; // Default: Da Nang
  Map<String, dynamic>? _weatherData;
  String _weatherDesc = "--";
  String _lightCondition = "--";

  http.Client? _client;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _connectToSSE();
    _fetchWeather();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _client?.close();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final data = await _weatherService.getWeather(
      lat: _selectedCity.lat,
      lon: _selectedCity.lon,
    );
    if (data != null && mounted) {
      setState(() {
        _weatherData = data;
        final current = data['current'];
        final code = current['weather_code'];
        _weatherDesc = _weatherService.getWeatherDescription(code);
        _lightCondition = _weatherService.getLightCondition(current);
      });
    }
  }

  void _openCitySelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
    );

    if (result != null && result is City) {
      setState(() {
        _selectedCity = result;
        _weatherData = null; // Reset to show loading/update
        _weatherDesc = "Đang tải...";
        _lightCondition = "--";
      });
      _fetchWeather();
    }
  }

  void _connectToSSE() async {
    final baseUrl = dotenv.env['BACKEND_URL'] ?? "http://10.0.2.2:8000";
    final url = Uri.parse("$baseUrl/events");

    try {
      _client = http.Client();
      final request = http.Request("GET", url);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _client!.send(request);

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith("data: ")) {
                try {
                  final data = line.substring(6).trim();
                  if (data.isEmpty) return;

                  final decoded = jsonDecode(data);
                  final newEvent = FarmEvent.fromJson(decoded);

                  if (mounted) {
                    setState(() {
                      _latestEvent = newEvent;
                      _eventHistory.insert(0, newEvent);
                      if (_eventHistory.length > 50) _eventHistory.removeLast();
                    });
                  }
                } catch (e) {
                  debugPrint("Lỗi parse JSON: $e");
                }
              }
            },
            onError: (e) {
              debugPrint("Lỗi kết nối Stream: $e");
              _reconnect();
            },
            onDone: () {
              debugPrint("Server đã đóng kết nối.");
              _reconnect();
            },
          );
    } catch (e) {
      debugPrint("Không thể kết nối Backend: $e");
      _reconnect();
    }
  }

  void _reconnect() {
    _sseSubscription?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _connectToSSE();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "FARM AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: DashboardView(
        latestEvent: _latestEvent,
        weatherDesc: _weatherDesc,
        lightCondition: _lightCondition,
        cityName: _selectedCity.name,
        onWeatherTap: _openCitySelection,
        onRefresh: _fetchWeather,
        onOpenDashboard: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SensorDashboardScreen(
                historyData: _eventHistory,
                cityName: _selectedCity.name,
                weatherCondition: _weatherDesc,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E2630),
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF121212),
              image: DecorationImage(
                image: NetworkImage(
                  "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=1000",
                ),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            accountName: Text(
              "Group 4 Admin",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("Smart Farm AIoT System"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Color(0xFF00E676),
              child: Icon(Icons.eco, color: Colors.black, size: 35),
            ),
          ),
          _buildDrawerItem(
            Icons.grid_view_rounded,
            "Tổng quan",
            onTap: () => Navigator.pop(context), // Already on Home
          ),
          _buildDrawerItem(
            Icons.camera_alt_rounded,
            "AI Camera Gallery",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AICameraGalleryScreen(events: _eventHistory),
                ),
              );
            },
          ),
          _buildDrawerItem(
            Icons.water_drop,
            "Điều khiển Bơm",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PumpControlScreen()),
              );
            },
          ),
          _buildDrawerItem(
            Icons.history_edu,
            "Nhật ký hoạt động",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogScreen()),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: const Text(
              "Về dự án",
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}

class DashboardView extends StatelessWidget {
  final FarmEvent? latestEvent;
  final VoidCallback onOpenDashboard;
  final String weatherDesc;
  final String lightCondition;
  final String cityName;
  final VoidCallback? onWeatherTap;
  final Future<void> Function() onRefresh;

  const DashboardView({
    super.key,
    this.latestEvent,
    required this.onOpenDashboard,
    required this.onRefresh,
    this.weatherDesc = "--",
    this.lightCondition = "--",
    this.cityName = "Đà Nẵng",
    this.onWeatherTap,
  });

  @override
  Widget build(BuildContext context) {
    final temp = latestEvent?.temp.toStringAsFixed(1) ?? "--";
    final soil = latestEvent?.soil.toStringAsFixed(1) ?? "--";
    final humi = latestEvent?.humi.toStringAsFixed(1) ?? "--";
    final status = latestEvent?.plantStatus ?? "Đang kết nối...";
    final isConnected = latestEvent != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2A2A), Color(0xFF121212)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1E2630),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),
              // Header Status
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF00E676)
                          : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isConnected)
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Trạng thái: $status",
                    style: TextStyle(
                      color: isConnected
                          ? const Color(0xFF00E676)
                          : Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // Analytic Card
              InkWell(
                onTap: onOpenDashboard,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Phân tích dữ liệu",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Xem biểu đồ thời gian thực",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Sensors Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  SensorCard(
                    title: "Nhiệt độ",
                    value: temp,
                    unit: "°C",
                    icon: Icons.thermostat,
                    iconColor: Colors.orange,
                  ),
                  SensorCard(
                    title: "Độ ẩm đất",
                    value: soil,
                    unit: "%",
                    icon: Icons.grass,
                    iconColor: Colors.brown,
                  ),
                  SensorCard(
                    title: "Độ ẩm KK",
                    value: humi,
                    unit: "%",
                    icon: Icons.cloud_queue,
                    iconColor: Colors.blue,
                  ),
                  SensorCard(
                    title: "Thời tiết ($cityName)",
                    value: weatherDesc,
                    unit: lightCondition,
                    icon: Icons.wb_sunny,
                    iconColor: Colors.yellow,
                    onTap: onWeatherTap,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "Điều khiển nhanh",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildActionBtn(
                    context,
                    "Hệ thống Bơm",
                    Icons.water_drop,
                    Colors.green,
                    const PumpControlScreen(),
                  ),
                  const SizedBox(width: 15),
                  _buildActionBtn(
                    context,
                    "Lịch sử Log",
                    Icons.history,
                    Colors.purple,
                    const LogScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2630),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
