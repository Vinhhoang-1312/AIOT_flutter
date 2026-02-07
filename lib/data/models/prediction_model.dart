class Prediction {
  final String predictionType;
  final double confidence;
  final String result;
  final DateTime timestamp;

  Prediction({
    required this.predictionType,
    required this.confidence,
    required this.result,
    required this.timestamp,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      predictionType: json['prediction_type'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      result: json['result'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
