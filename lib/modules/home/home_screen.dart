import 'package:flutter/material.dart';
import '../../widgets/sensor_card.dart';
import '../camera/camera_screen.dart';
import '../about/about_screen.dart';
import '../controls/pump_control_screen.dart';
import 'log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const CameraScreen(),
    const PumpControlScreen(),
    const LogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "FARM AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
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
                opacity: 0.4,
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
          _buildDrawerItem(Icons.center_focus_strong, "Camera AI", 1),
          _buildDrawerItem(Icons.water_drop, "Điều khiển Bơm", 2), // Mới
          _buildDrawerItem(Icons.history_edu, "Nhật ký hoạt động", 3), // Mới

          const Divider(color: Colors.white24),

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
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
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
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Đóng Drawer
      },
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Text(
            "Hệ thống\nĐang hoạt động",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 30),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: const [
              SensorCard(
                title: "Nhiệt độ",
                value: "28.5",
                unit: "°C",
                icon: Icons.thermostat,
                iconColor: Colors.orange,
              ),
              SensorCard(
                title: "Độ ẩm đất",
                value: "62",
                unit: "%",
                icon: Icons.water_drop,
                iconColor: Colors.blueAccent,
              ),
              SensorCard(
                title: "Ánh sáng",
                value: "1.2k",
                unit: "Lux",
                icon: Icons.wb_sunny,
                iconColor: Colors.yellow,
              ),
              SensorCard(
                title: "Không khí",
                value: "45",
                unit: "%",
                icon: Icons.air,
                iconColor: Colors.cyan,
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
              _buildQuickAction(
                context,
                "Bật Bơm",
                Icons.power_settings_new,
                Colors.blue,
                const PumpControlScreen(),
              ),
              const SizedBox(width: 15),
              _buildQuickAction(
                context,
                "Xem Log",
                Icons.history,
                Colors.purple,
                const LogScreen(),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2630),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
