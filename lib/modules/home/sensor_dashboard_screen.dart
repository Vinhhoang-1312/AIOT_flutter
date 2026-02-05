import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/farm_event_model.dart';
import '../../core/constants/ai_constants.dart';

class SensorDashboardScreen extends StatefulWidget {
  final List<FarmEvent> historyData;

  const SensorDashboardScreen({super.key, required this.historyData});

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  final TextEditingController _plantInfoController = TextEditingController();
  String _selectedRange = 'Ngày';
  String _selectedSensor = 'Temp';

  String _aiAnalysis = "Đang kết nối với trí tuệ nhân tạo...";
  bool _isLoadingAI = false;

  List<FlSpot> _realDataPoints = [];
  List<FlSpot> _referencePoints = [];

  @override
  void initState() {
    super.initState();
    _generateChartData();
    _fetchAIAnalysis();
  }

  Future<void> _fetchAIAnalysis() async {
    if (!mounted) return;
    setState(() => _isLoadingAI = true);

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) throw Exception("Thiếu API Key");

      // 1. Cập nhật model sang 2.5 Flash Lite (hoặc gemini-3-flash)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
      );

      // 2. Lấy thông tin cây từ TextField
      String plantContext = _plantInfoController.text.isEmpty
          ? "Cây trồng chưa xác định"
          : _plantInfoController.text;

      // 3. Chuẩn bị dữ liệu lịch sử (lấy nhiều hơn để AI so sánh)
      String dataSummary = widget.historyData.isEmpty
          ? "(Dữ liệu mô phỏng): Nhiệt độ 30°C, Đất 50%"
          : widget.historyData
                .take(10)
                .map(
                  (e) =>
                      "Lúc ${DateFormat('HH:mm dd/MM').format(e.timestamp)}: T:${e.temp}°C, Đất:${e.soil}%, Khí:${e.humi}%",
                )
                .join("\n");

      // 4. Tạo Prompt kết hợp cả thông tin cây + dữ liệu cảm biến
      final prompt =
          """
        Thông tin về cây: $plantContext.
        Dữ liệu cảm biến lịch sử và hiện tại:
        $dataSummary
        
        Nhiệm vụ: Dựa vào loại cây này và dữ liệu trên, hãy phân tích tình trạng sức khỏe của cây và đưa ra lời khuyên chăm sóc ngắn gọn.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (mounted) {
        setState(() {
          _aiAnalysis = response.text ?? "AI không trả về kết quả.";
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAnalysis = "Lỗi kết nối AI: ${e.toString()}";
          _isLoadingAI = false;
        });
      }
    }
  }

  void _generateChartData() {
    _realDataPoints.clear();
    _referencePoints.clear();
    final random = Random();

    // Số lượng điểm dữ liệu hiển thị
    int points = _selectedRange == 'Ngày'
        ? 24 // 24 giờ
        : (_selectedRange == 'Tuần' ? 7 : 30); // 7 ngày hoặc 30 ngày

    // Giá trị tham chiếu (đường nét đứt)
    double idealVal = _selectedSensor == 'Temp'
        ? 28.0
        : (_selectedSensor == 'Humi' ? 75.0 : 60.0);

    // Giá trị nền random (nếu chưa map data thật)
    double baseVal = _selectedSensor == 'Temp'
        ? 27
        : (_selectedSensor == 'Humi' ? 70 : 55);

    // Logic: Nếu có historyData thì dùng, không thì random
    if (widget.historyData.isNotEmpty && widget.historyData.length >= points) {
      // TODO: Logic map dữ liệu thật vào đây sau này
      // Tạm thời vẫn giữ random để UI đẹp khi test
    }

    for (int i = 0; i < points; i++) {
      _realDataPoints.add(
        FlSpot(i.toDouble(), baseVal + random.nextDouble() * 5),
      );
      _referencePoints.add(FlSpot(i.toDouble(), idealVal));
    }
    setState(() {});
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_selectedRange == 'Ngày') {
      return "Hôm nay, ${DateFormat('dd/MM').format(now)}";
    } else if (_selectedRange == 'Tuần') {
      return "7 ngày qua";
    } else {
      return "Tháng ${now.month}/${now.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Phân tích hệ thống", style: TextStyle(fontSize: 18)),
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
              Text(
                _getDateRangeText(),
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 15),
              _buildTimeFilter(),
              const SizedBox(height: 20),
              _buildSensorSelector(),
              const SizedBox(height: 30),

              // Chiều cao biểu đồ
              SizedBox(height: 300, child: _buildChart()),

              const SizedBox(height: 15),
              _buildLegend(),
              const SizedBox(height: 30),
              _buildPlantInput(),

              const SizedBox(height: 20),
              _buildAIAnalysisText(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET UI ---

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Ngày', 'Tuần', 'Tháng'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _selectedRange = range);
                _generateChartData();
              },
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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _sensorBtn('Temp', 'Nhiệt độ', Icons.thermostat),
        _sensorBtn('Humi', 'Độ ẩm KK', Icons.water_drop),
        _sensorBtn('Soil', 'Độ ẩm Đất', Icons.grass),
      ],
    );
  }

  Widget _sensorBtn(String key, String label, IconData icon) {
    final isSelected = _selectedSensor == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedSensor = key);
        _generateChartData();
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : Colors.white24,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white24,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      // Tắt hiệu ứng chuyển động để biểu đồ chuyên nghiệp hơn
      duration: Duration.zero,
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                String timeLabel = "";
                if (_selectedRange == 'Ngày') {
                  timeLabel = "${barSpot.x.toInt()}h";
                } else if (_selectedRange == 'Tuần') {
                  final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  timeLabel = days[barSpot.x.toInt() % 7];
                } else {
                  timeLabel = "Ngày ${barSpot.x.toInt() + 1}";
                }

                return LineTooltipItem(
                  "$timeLabel\n",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: "${barSpot.y.toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _selectedRange == 'Tháng'
                  ? 5
                  : (_selectedRange == 'Ngày' ? 4 : 1),
              getTitlesWidget: (val, meta) {
                String text = "";
                if (_selectedRange == 'Tuần') {
                  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  int index = val.toInt();
                  if (index >= 0 && index < days.length) text = days[index];
                } else if (_selectedRange == 'Ngày') {
                  text = "${val.toInt()}h";
                } else {
                  text = "${val.toInt() + 1}";
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _realDataPoints,
            isCurved: true,
            color: const Color(0xFF00E676),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00E676).withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: _referencePoints,
            isCurved: false,
            color: Colors.white24,
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(const Color(0xFF00E676)),
        const SizedBox(width: 5),
        const Text(
          "Thực tế",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(width: 20),
        _dot(Colors.white24),
        const SizedBox(width: 5),
        const Text(
          "Ngưỡng tối ưu",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _dot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _buildPlantInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "THÔNG TIN CÂY TRỒNG",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _plantInfoController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Ví dụ: Cây dưa lưới, cao 1m, đang ra hoa...",
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E2630),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIAnalysisText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "GEMINI AI PHÂN TÍCH",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (_isLoadingAI)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiAnalysis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoadingAI ? null : _fetchAIAnalysis,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Cập nhật phân tích"),
            ),
          ),
        ],
      ),
    );
  }
}
