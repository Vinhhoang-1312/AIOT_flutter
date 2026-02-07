class Log {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? details;

  Log({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      level: json['level'] ?? 'INFO',
      message: json['message'] ?? '',
      details: json['details'],
    );
  }
}
