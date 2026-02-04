import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/farm_event_model.dart';

class SensorDashboardScreen extends StatefulWidget {
  final List<FarmEvent> historyData;

  const SensorDashboardScreen({super.key, required this.historyData});

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  String _selectedRange = 'Ngày'; // 'Ngày', 'Tuần', 'Tháng'
  String _selectedSensor = 'Temp'; // 'Temp', 'Humi', 'Soil'

  // Mock data riêng cho biểu đồ để hiển thị đẹp khi chưa có data thật nhiều
  List<FlSpot> _realDataPoints = [];
  List<FlSpot> _aiIdealDataPoints = [];

  @override
  void initState() {
    super.initState();
    _generateChartData();
  }

  // Hàm tạo dữ liệu giả lập dựa trên lựa chọn (Ngày/Tuần)
  void _generateChartData() {
    _realDataPoints.clear();
    _aiIdealDataPoints.clear();
    final random = Random();

    int points = _selectedRange == 'Ngày'
        ? 24
        : (_selectedRange == 'Tuần' ? 7 : 30);
    double baseVal = _selectedSensor == 'Temp'
        ? 30
        : (_selectedSensor == 'Humi' ? 70 : 50);

    for (int i = 0; i < points; i++) {
      // Dữ liệu thực tế (biến động nhiều)
      double noise = (random.nextDouble() - 0.5) * 10;
      _realDataPoints.add(FlSpot(i.toDouble(), baseVal + noise));

      // Dữ liệu AI Lý tưởng (Đường mượt mà hơn, chuẩn healthy)
      // Ví dụ: AI tính toán cây cần nhiệt độ ổn định hơn
      double idealNoise = sin(i / 2) * 2;
      _aiIdealDataPoints.add(FlSpot(i.toDouble(), baseVal + idealNoise));
    }
    setState(() {});
  }

  void _onFilterChanged(String range) {
    setState(() {
      _selectedRange = range;
      _generateChartData(); // Tạo lại data giả khác để demo hiệu ứng
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Phân tích AI"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TAB BAR CHỌN THỜI GIAN ---
              _buildTimeFilter(),

              const SizedBox(height: 20),

              // --- 2. TAB CHỌN LOẠI CẢM BIẾN ---
              _buildSensorSelector(),

              const SizedBox(height: 30),

              // --- 3. BIỂU ĐỒ ---
              SizedBox(
                height: 350, // Tăng chiều cao để không bị chật
                child: _buildChart(),
              ),

              const SizedBox(height: 20),
              _buildLegend(),

              const SizedBox(height: 30),
              _buildAIAnalysisText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Ngày', 'Tuần', 'Tháng'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterChanged(range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSensorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sensorBtn('Temp', 'Nhiệt độ', Icons.thermostat),
        _sensorBtn('Humi', 'Độ ẩm KK', Icons.water_drop),
        _sensorBtn('Soil', 'Độ ẩm Đất', Icons.grass),
      ],
    );
  }

  Widget _sensorBtn(String key, String label, IconData icon) {
    final isSelected = _selectedSensor == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSensor = key;
          _generateChartData();
        });
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isSelected
                ? Colors.blueAccent
                : const Color(0xFF1E2630),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        // Cấu hình Grid
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),

        // Cấu hình trục và tiêu đề
        titlesData: FlTitlesData(
          show: true,
          // Ẩn trục phải và trên
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Trục dưới (Thời gian)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, // Tăng khoảng trống để chữ không bị cắt
              interval: _selectedRange == 'Ngày' ? 4 : 1, // Dãn cách label
              getTitlesWidget: (value, meta) {
                String text = '';
                if (_selectedRange == 'Ngày') {
                  text = '${value.toInt()}h';
                } else if (_selectedRange == 'Tuần') {
                  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    text = days[value.toInt()];
                  }
                } else {
                  if (value.toInt() % 5 == 0) text = '${value.toInt() + 1}';
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                );
              },
            ),
          ),

          // Trục trái (Giá trị)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // Tăng khoảng trống bên trái
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        // Cấu hình đường
        lineBarsData: [
          // 1. Đường dữ liệu Thực tế (Xanh lá / Đậm)
          LineChartBarData(
            spots: _realDataPoints,
            isCurved: true,
            color: const Color(0xFF00E676),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00E676).withOpacity(0.1), // Đổ bóng nhẹ
            ),
          ),

          // 2. Đường AI Lý tưởng / Tiêu chuẩn (Vàng / Nét đứt)
          LineChartBarData(
            spots: _aiIdealDataPoints,
            isCurved: true,
            color: Colors.orangeAccent.withOpacity(0.8),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5], // TẠO NÉT ĐỨT
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Thực tế", const Color(0xFF00E676), false),
        const SizedBox(width: 20),
        _legendItem("AI Tiêu chuẩn", Colors.orangeAccent, true),
      ],
    );
  }

  Widget _legendItem(String text, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 6, color: color),
                    Container(width: 6, color: color),
                  ],
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAIAnalysisText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.blueAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Đánh giá AI",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Dữ liệu thực tế đang bám sát tiêu chuẩn healthy. Tuy nhiên, vào lúc 14h nhiệt độ có xu hướng tăng nhẹ so với mức lý tưởng. Cần theo dõi thêm hệ thống tưới.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
