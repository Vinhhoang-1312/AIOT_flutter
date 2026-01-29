import 'package:flutter/material.dart';
import '../../widgets/sensor_card.dart';
import '../camera/camera_screen.dart';
import '../about/about_screen.dart';

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
    const Center(child: Text("Control Panel")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("FARM AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1E2630)),
            accountName: Text("Group 4 Admin"),
            accountEmail: Text("Smart Farm AIoT System"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.eco, color: Colors.black, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text("Tổng quan"),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.center_focus_strong),
            title: const Text("Camera AI"),
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Về dự án"),
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
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          const Text(
            "Hệ thống\nĐang hoạt động",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
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
        ],
      ),
    );
  }
}
