// lib/modules/home/log_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/api_service.dart';
import '../../data/models/log_model.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<Log>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = ApiService.getStatusLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = ApiService.getStatusLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Nhật Ký Hoạt Động",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
          )
        ],
      ),
      body: FutureBuilder<List<Log>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Lỗi tải dữ liệu: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Không có dữ liệu nhật ký.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final logs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogItem(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogItem(Log log) {
    Color iconColor;
    IconData iconData;

    switch (log.level.toUpperCase()) {
      case 'WARNING':
      case 'ERROR':
        iconColor = Colors.orange;
        iconData = Icons.warning_amber_rounded;
        break;
      case 'SUCCESS':
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        break;
      default:
        iconColor = Colors.blue;
        iconData = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: iconColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                DateFormat('HH:mm').format(log.timestamp),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd/MM').format(log.timestamp),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Icon(iconData, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.message,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (log.details != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      log.details!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
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

