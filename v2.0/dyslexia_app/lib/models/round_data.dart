/// Modelo para datos de una ronda individual (basado en dataset)
class RoundData {
  final int roundNumber;
  final int clicks;
  final int hits;
  final int misses;
  final int score;
  final double accuracy;
  final double missrate;
  final DateTime timestamp;

  RoundData({
    required this.roundNumber,
    required this.clicks,
    required this.hits,
    required this.misses,
    required this.score,
    required this.accuracy,
    required this.missrate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'round_number': roundNumber,
    'clicks': clicks,
    'hits': hits,
    'misses': misses,
    'score': score,
    'accuracy': accuracy,
    'missrate': missrate,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RoundData.fromJson(Map<String, dynamic> json) => RoundData(
    roundNumber: json['round_number'],
    clicks: json['clicks'],
    hits: json['hits'],
    misses: json['misses'],
    score: json['score'],
    accuracy: json['accuracy'],
    missrate: json['missrate'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  /// Calcular desde datos brutos
  factory RoundData.calculate({
    required int roundNumber,
    required int clicks,
    required int hits,
    required int misses,
  }) {
    final score = hits;
    final accuracy = clicks > 0 ? hits / clicks : 0.0;
    final missrate = clicks > 0 ? misses / clicks : 0.0;

    return RoundData(
      roundNumber: roundNumber,
      clicks: clicks,
      hits: hits,
      misses: misses,
      score: score,
      accuracy: accuracy,
      missrate: missrate,
      timestamp: DateTime.now(),
    );
  }
}

/// Resultado completo de una actividad con 10 rondas
class ActivityRoundResult {
  final String activityId;
  final String activityName;
  final String? childId;
  final List<RoundData> rounds;
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalDuration;

  ActivityRoundResult({
    required this.activityId,
    required this.activityName,
    this.childId,
    required this.rounds,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
  });

  // Estadísticas agregadas
  int get totalClicks => rounds.fold(0, (sum, r) => sum + r.clicks);
  int get totalHits => rounds.fold(0, (sum, r) => sum + r.hits);
  int get totalMisses => rounds.fold(0, (sum, r) => sum + r.misses);
  int get totalScore => rounds.fold(0, (sum, r) => sum + r.score);

  double get averageAccuracy => rounds.isNotEmpty
      ? rounds.map((r) => r.accuracy).reduce((a, b) => a + b) / rounds.length
      : 0.0;

  double get averageMissrate => rounds.isNotEmpty
      ? rounds.map((r) => r.missrate).reduce((a, b) => a + b) / rounds.length
      : 0.0;

  Map<String, dynamic> toJson() => {
    'activity_id': activityId,
    'activity_name': activityName,
    'child_id': childId,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'total_duration_seconds': totalDuration.inSeconds,
    'total_clicks': totalClicks,
    'total_hits': totalHits,
    'total_misses': totalMisses,
    'total_score': totalScore,
    'average_accuracy': averageAccuracy,
    'average_missrate': averageMissrate,
  };

  factory ActivityRoundResult.fromJson(Map<String, dynamic> json) =>
      ActivityRoundResult(
        activityId: json['activity_id'],
        activityName: json['activity_name'],
        childId: json['child_id'],
        rounds: (json['rounds'] as List)
            .map((r) => RoundData.fromJson(r))
            .toList(),
        startTime: DateTime.parse(json['start_time']),
        endTime: DateTime.parse(json['end_time']),
        totalDuration: Duration(seconds: json['total_duration_seconds']),
      );
}
