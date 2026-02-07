import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/farm_event_model.dart';
import '../../data/services/api_service.dart';

class SensorDashboardScreen extends StatefulWidget {
  final List<FarmEvent> historyData;
  final String cityName;
  final String weatherCondition;

  const SensorDashboardScreen({
    super.key,
    required this.historyData,
    required this.cityName,
    required this.weatherCondition,
  });

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  String _selectedRange = 'Ngày';
  String _selectedSensor = 'Temp';

  String _aiAnalysis = "Nhấn 'Phân tích' để bắt đầu AI tư vấn.";
  String _currentModelUsed = "";
  bool _isLoadingAI = false;
  final TextEditingController _plantController = TextEditingController();

  List<FlSpot> _realDataPoints = [];
  List<FlSpot> _referencePoints = [];
  List<FarmEvent> _currentHistory = [];

  @override
  void initState() {
    super.initState();
    _currentHistory = widget.historyData;
    _loadData();
  }

  @override
  void dispose() {
    _plantController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final now = DateTime.now();
    DateTime startTime;
    String interval = '1h';

    if (_selectedRange == 'Ngày') {
      startTime = now.subtract(const Duration(hours: 24));
      interval = '1h'; // 24 điểm
    } else if (_selectedRange == 'Tuần') {
      startTime = now.subtract(const Duration(days: 7));
      interval = '6h'; // 28 điểm
    } else {
      startTime = now.subtract(const Duration(days: 30));
      interval = '1d'; // 30 điểm
    }

    final history = await ApiService.getEnvironmentHistory(
      startTime: startTime.toIso8601String(),
      endTime: now.toIso8601String(),
      interval: interval,
    );

    if (mounted) {
      setState(() {
        _currentHistory = history;
        _updateChartFromHistory();
      });
    }
  }

  Future<void> _fetchAIAnalysis() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAI = true;
      _aiAnalysis = "Đang tải phân tích...";
      _currentModelUsed = "";
    });

    final List<String?> keysToTry = [
      dotenv.env['GEMINI_API_KEY'],
      dotenv.env['GEMINI_BACKUP_KEY'],
    ];

    final List<String> modelsToTry = [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-3-flash',
      'gemma-3-27b',
      'gemma-3-12b',
      'gemma-3-4b',
    ];

    String lastError = "";

    try {
      String? result;
      String? successfulModel;

      outerLoop:
      for (var apiKey in keysToTry) {
        if (apiKey == null || apiKey.isEmpty) continue;

        for (var modelName in modelsToTry) {
          try {
            final model = GenerativeModel(model: modelName, apiKey: apiKey);

            // Construct Prompt
            final latest = _currentHistory.isNotEmpty
                ? _currentHistory.last
                : null;
            final temp = latest?.temp.toStringAsFixed(1) ?? "N/A";
            final humi = latest?.humi.toStringAsFixed(1) ?? "N/A";
            final soil = latest?.soil.toStringAsFixed(1) ?? "N/A";

            // Format raw history for Gemini
            String historyDataPoints = "";
            if (_currentHistory.isNotEmpty) {
              historyDataPoints = "Dữ liệu lịch sử ($_selectedRange qua):\n";
              // Lấy tối đa 30 điểm dữ liệu gần nhất để tránh quá tải prompt
              final displayHistory = _currentHistory.length > 30
                  ? _currentHistory.sublist(_currentHistory.length - 30)
                  : _currentHistory;

              historyDataPoints += displayHistory
                  .map((e) {
                    final timeStr = DateFormat(
                      'HH:mm dd/MM',
                    ).format(e.timestamp);
                    return "- $timeStr: Nhiệt độ ${e.temp.toStringAsFixed(1)}°C, Độ ẩm đất ${e.soil.toStringAsFixed(1)}%";
                  })
                  .join("\n");
            }

            final plantInfo = _plantController.text.trim();
            final plantContext = plantInfo.isNotEmpty
                ? "Thông tin cây trồng: \"$plantInfo\"."
                : "";

            final prompt =
                """
            Bạn là chuyên gia nông nghiệp AI.
            
            Dữ liệu lịch sử cụ thể:
            $historyDataPoints
            
            Dữ liệu mới nhất hiện tại: 
            - Nhiệt độ: $temp°C
            - Độ ẩm KK: $humi%
            - Độ ẩm đất: $soil%
            
            Vị trí: ${widget.cityName}. Thời tiết: ${widget.weatherCondition}.
            $plantContext
            
            Hãy phân tích kỹ và trả lời ngắn gọn (dưới 250 từ) theo cấu trúc sau:
            1. Nhận xét chung & Diễn biến: Đánh giá môi trường, thời tiết hiện tại và soi kỹ danh sách lịch sử để phát hiện bất thường (chỉ rõ thời điểm nếu có biến động đột ngột).
            2. Đánh giá sức khỏe & Độ ổn định: Dựa trên thông tin cây trồng và chỉ số, hãy kết luận hệ thống đang "Ổn" hay "Không ổn". Đánh giá sức khỏe cây và rủi ro (sâu bệnh, sốc nhiệt...).
            3. Đề xuất hành động: Chỉ dẫn cụ thể (tưới nước, che chắn, ánh sáng...) cho cả trường hợp cây ngoài trời và trong nhà.
            """;

            final content = [Content.text(prompt)];
            final response = await model.generateContent(content);

            if (response.text != null && response.text!.isNotEmpty) {
              result = response.text;
              successfulModel = modelName;
              break outerLoop; // Success! Exit both loops
            }
          } catch (e) {
            lastError = e.toString();
            debugPrint(
              "Lỗi Model $modelName với API Key ...${apiKey.substring(apiKey.length - 5)}: $e",
            );
            continue;
          }
        }
      }

      if (mounted) {
        setState(() {
          if (result != null) {
            _aiAnalysis = result;
            _currentModelUsed = successfulModel ?? "Không xác định";
          } else {
            _aiAnalysis = "Lỗi kết nối AI. Lỗi cuối:\n$lastError";
          }
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAnalysis =
              "Lỗi phân tích: $e\n(Kiểm tra GEMINI_API_KEY trong .env)";
          _isLoadingAI = false;
        });
      }
    }
  }

  void _updateChartFromHistory() {
    _realDataPoints.clear();
    _referencePoints.clear();

    _currentHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double idealVal = _selectedSensor == 'Temp'
        ? 28.0
        : (_selectedSensor == 'Humi' ? 75.0 : 60.0);

    for (int i = 0; i < _currentHistory.length; i++) {
      final evt = _currentHistory[i];
      double y;
      if (_selectedSensor == 'Temp') {
        y = evt.temp;
      } else if (_selectedSensor == 'Humi') {
        y = evt.humi;
      } else {
        y = evt.soil;
      }
      _realDataPoints.add(FlSpot(i.toDouble(), y));
      _referencePoints.add(FlSpot(i.toDouble(), idealVal));
    }

    if (mounted) setState(() {});
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF00E676),
        backgroundColor: const Color(0xFF1E2630),
        child: SingleChildScrollView(
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

                if (_currentHistory.isNotEmpty)
                  SizedBox(height: 300, child: _buildChart())
                else
                  const SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        "Đang tải dữ liệu...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),

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
      ),
    );
  }

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
                _fetchHistory();
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
        _updateChartFromHistory();
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
      duration: Duration.zero,
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                String timeLabel = "";
                if (barSpot.x.toInt() >= 0 &&
                    barSpot.x.toInt() < _currentHistory.length) {
                  final evt = _currentHistory[barSpot.x.toInt()];
                  timeLabel = DateFormat('HH:mm dd/MM').format(evt.timestamp);
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
              interval: _currentHistory.length > 10
                  ? (_currentHistory.length / 5).toDouble()
                  : 1,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < _currentHistory.length) {
                  final evt = _currentHistory[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(evt.timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thông tin cây trồng:",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _plantController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "VD: Cây dừa cao 3m, đang ra quả...",
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
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
                "GEMINI AI CONTEXT",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              if (_currentModelUsed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "(${_currentModelUsed.contains('lite')
                        ? '2.0 Flash Lite'
                        : _currentModelUsed.contains('2.0')
                        ? '2.0 Flash'
                        : '1.5 Flash'})",
                    style: TextStyle(
                      color: Colors.blueAccent.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
              label: const Text("Phân tích"),
            ),
          ),
        ],
      ),
    );
  }
}
