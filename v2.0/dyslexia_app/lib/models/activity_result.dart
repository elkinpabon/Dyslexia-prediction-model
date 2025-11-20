/// Modelo de resultado de actividad
class ActivityResult {
  final String activityId;
  final String activityName;
  final DateTime timestamp;
  final String result; // "SÍ" o "NO"
  final double probability;
  final double confidence;
  final Map<String, dynamic> details;
  final Duration duration;

  ActivityResult({
    required this.activityId,
    required this.activityName,
    required this.timestamp,
    required this.result,
    required this.probability,
    required this.confidence,
    required this.details,
    required this.duration,
  });

  // Convertir a JSON para almacenamiento
  Map<String, dynamic> toJson() => {
    'activityId': activityId,
    'activityName': activityName,
    'timestamp': timestamp.toIso8601String(),
    'result': result,
    'probability': probability,
    'confidence': confidence,
    'details': details,
    'durationSeconds': duration.inSeconds,
  };

  // Crear desde JSON
  factory ActivityResult.fromJson(Map<String, dynamic> json) => ActivityResult(
    activityId: json['activityId'],
    activityName: json['activityName'],
    timestamp: DateTime.parse(json['timestamp']),
    result: json['result'],
    probability: json['probability'].toDouble(),
    confidence: json['confidence'].toDouble(),
    details: json['details'],
    duration: Duration(seconds: json['durationSeconds']),
  );

  // Obtener nivel de riesgo
  String get riskLevel {
    if (probability < 0.3) return "Bajo";
    if (probability < 0.7) return "Medio";
    return "Alto";
  }

  // Obtener color según resultado
  int get resultColor {
    if (result == "SÍ") return 0xFFE57373; // Rojo suave
    return 0xFF81C784; // Verde suave
  }
}
