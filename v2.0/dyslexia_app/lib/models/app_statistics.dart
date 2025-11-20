import 'activity_result.dart';

/// Estadísticas globales de la aplicación
class AppStatistics {
  final int totalActivities;
  final int totalIndicators; // Cantidad de resultados "SÍ"
  final int totalNoIndicators; // Cantidad de resultados "NO"
  final double averageConfidence;
  final double averageProbability;
  final Map<String, int> activityBreakdown;
  final List<ActivityResult> recentResults;

  AppStatistics({
    this.totalActivities = 0,
    this.totalIndicators = 0,
    this.totalNoIndicators = 0,
    this.averageConfidence = 0.0,
    this.averageProbability = 0.0,
    Map<String, int>? activityBreakdown,
    List<ActivityResult>? recentResults,
  }) : activityBreakdown = activityBreakdown ?? {},
       recentResults = recentResults ?? [];

  double get indicatorPercentage =>
      totalActivities > 0 ? (totalIndicators / totalActivities) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
    'totalActivities': totalActivities,
    'totalIndicators': totalIndicators,
    'totalNoIndicators': totalNoIndicators,
    'averageConfidence': averageConfidence,
    'averageProbability': averageProbability,
    'activityBreakdown': activityBreakdown,
    'recentResults': recentResults.map((r) => r.toJson()).toList(),
  };

  factory AppStatistics.fromJson(Map<String, dynamic> json) => AppStatistics(
    totalActivities: json['totalActivities'] ?? 0,
    totalIndicators: json['totalIndicators'] ?? 0,
    totalNoIndicators: json['totalNoIndicators'] ?? 0,
    averageConfidence: (json['averageConfidence'] ?? 0.0).toDouble(),
    averageProbability: (json['averageProbability'] ?? 0.0).toDouble(),
    activityBreakdown: Map<String, int>.from(json['activityBreakdown'] ?? {}),
    recentResults:
        (json['recentResults'] as List?)
            ?.map((r) => ActivityResult.fromJson(r))
            .toList() ??
        [],
  );

  // Calcular estadísticas desde lista de resultados
  factory AppStatistics.fromResults(List<ActivityResult> results) {
    if (results.isEmpty) return AppStatistics();

    final indicators = results.where((r) => r.result == "SÍ").length;
    final noIndicators = results.where((r) => r.result == "NO").length;
    final avgConfidence =
        results.map((r) => r.confidence).reduce((a, b) => a + b) /
        results.length;
    final avgProbability =
        results.map((r) => r.probability).reduce((a, b) => a + b) /
        results.length;

    final breakdown = <String, int>{};
    for (var result in results) {
      breakdown[result.activityId] = (breakdown[result.activityId] ?? 0) + 1;
    }

    return AppStatistics(
      totalActivities: results.length,
      totalIndicators: indicators,
      totalNoIndicators: noIndicators,
      averageConfidence: avgConfidence,
      averageProbability: avgProbability,
      activityBreakdown: breakdown,
      recentResults: results.take(10).toList(),
    );
  }
}
