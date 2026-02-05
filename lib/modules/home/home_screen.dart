import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../data/models/farm_event_model.dart';
import '../../widgets/sensor_card.dart';
import '../camera/camera_screen.dart';
import '../controls/pump_control_screen.dart';
import 'log_screen.dart';
import 'sensor_dashboard_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // List chứa lịch sử dữ liệu
  final List<FarmEvent> _eventHistory = [];
  // Dữ liệu mới nhất
  FarmEvent? _latestEvent;
  Timer? _timer;

  // Ảnh mock dùng chung
  final List<String> _mockImages = [
    "https://images.unsplash.com/photo-1545239351-ef056c5983f3?q=80&w=500", // Healthy
    "https://images.unsplash.com/photo-1520412099551-6296b0db5c04?q=80&w=500", // Dry
    "https://images.unsplash.com/photo-1485955900006-10f4d324d411?q=80&w=500", // Cactus
    "https://images.unsplash.com/photo-1592419044706-39796d40f98c?w=500", // Another plant
  ];

  @override
  void initState() {
    super.initState();
    // 1. Tạo ngay dữ liệu ban đầu để Gallery không bị trống
    _generateInitialMockData();
    // 2. Sau đó mới bắt đầu chạy stream giả lập
    _startSimulatedStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- HÀM MỚI: TẠO DỮ LIỆU GIẢ NGAY LẬP TỨC ---
  void _generateInitialMockData() {
    final random = Random();
    // Tạo sẵn 3 event quá khứ có ảnh
    for (int i = 0; i < 3; i++) {
      _eventHistory.add(
        FarmEvent(
          // Lùi thời gian lại một chút cho thật (cách nhau 15p)
          timestamp: DateTime.now().subtract(Duration(minutes: (i + 1) * 15)),
          soil: 50.0 + random.nextDouble() * 15,
          temp: 28.0 + random.nextDouble() * 5,
          humi: 65.0 + random.nextDouble() * 10,
          anomalyStatus: "Normal",
          plantStatus: "Healthy",
          // Đảm bảo luôn có ảnh
          imageBase64: _mockImages[i % _mockImages.length],
        ),
      );
    }
    // Cập nhật event mới nhất là cái đầu tiên vừa tạo
    if (_eventHistory.isNotEmpty) {
      _latestEvent = _eventHistory.first;
    }
    setState(() {}); // Cập nhật UI ngay
  }

  // --- HÀM GIẢ LẬP STREAM (Chạy liên tục) ---
  void _startSimulatedStream() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final random = Random();

      final newEvent = FarmEvent(
        timestamp: DateTime.now(),
        soil: 40.0 + random.nextDouble() * 20,
        temp: 26.0 + random.nextDouble() * 6,
        humi: 55.0 + random.nextDouble() * 20,
        anomalyStatus: random.nextInt(10) > 8 ? "Warning" : "Normal",
        plantStatus: random.nextBool() ? "Healthy" : "Needs Water",
        // 50% cơ hội có ảnh mới khi stream chạy
        imageBase64: random.nextBool()
            ? _mockImages[random.nextInt(_mockImages.length)]
            : null,
      );

      if (mounted) {
        setState(() {
          _latestEvent = newEvent;
          _eventHistory.insert(0, newEvent); // Đưa dữ liệu mới lên đầu list
          if (_eventHistory.length > 50) _eventHistory.removeLast();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardView(
        latestEvent: _latestEvent,
        onOpenDashboard: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SensorDashboardScreen(historyData: _eventHistory),
            ),
          );
        },
      ),
      // Truyền list dữ liệu đã có sẵn ảnh vào đây
      AICameraGalleryScreen(events: _eventHistory),
      const PumpControlScreen(),
      const LogScreen(),
    ];

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
      body: pages[_selectedIndex],
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
          _buildDrawerItem(Icons.grid_view_rounded, "Tổng quan", 0),
          _buildDrawerItem(Icons.camera_alt_rounded, "AI Camera Gallery", 1),
          _buildDrawerItem(Icons.water_drop, "Điều khiển Bơm", 2),
          _buildDrawerItem(Icons.history_edu, "Nhật ký hoạt động", 3),
          const Spacer(),
          const Divider(color: Colors.white10),
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

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF00E676) : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF00E676) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.05),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

// --- DASHBOARD VIEW ---
class DashboardView extends StatelessWidget {
  final FarmEvent? latestEvent;
  final VoidCallback onOpenDashboard;
  const DashboardView({
    super.key,
    this.latestEvent,
    required this.onOpenDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final temp = latestEvent?.temp.toStringAsFixed(1) ?? "--";
    final soil = latestEvent?.soil.toStringAsFixed(1) ?? "--";
    final humi = latestEvent?.humi.toStringAsFixed(1) ?? "--";
    final status = latestEvent?.plantStatus ?? "Đang kết nối...";

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2A2A), Color(0xFF121212)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 30),

            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Trạng thái: $status",
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Button Chart
            InkWell(
              onTap: onOpenDashboard,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 15),
                    const Column(
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
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
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
                const SensorCard(
                  title: "Ánh sáng",
                  value: "1.2k",
                  unit: "Lux",
                  icon: Icons.wb_sunny,
                  iconColor: Colors.yellow,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Tiện ích nhanh",
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
                  "Bật Bơm",
                  Icons.water_drop,
                  Colors.green,
                  const PumpControlScreen(),
                ),
                const SizedBox(width: 15),
                _buildActionBtn(
                  context,
                  "Nhật ký",
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2630),
            borderRadius: BorderRadius.circular(16),
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
