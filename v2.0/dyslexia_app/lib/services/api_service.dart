import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../models/activity_result.dart';
import '../models/round_data.dart';

/// Servicio para comunicación con el backend Flask
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _logger = Logger();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Verificar estado del servidor
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.apiBaseUrl}/health'))
          .timeout(const Duration(seconds: 3));

      _isConnected = response.statusCode == 200;
      _logger.i('Backend health check: $_isConnected');
      return _isConnected;
    } catch (e) {
      _logger.e('Error checking backend health: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Obtener información del modelo ML
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.apiBaseUrl}/model/info'))
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching model info: $e');
      return null;
    }
  }

  /// Evaluar actividad de secuencias
  Future<ActivityResult?> evaluateSequence({
    required List<String> userSequence,
    required List<String> correctSequence,
    required double time,
  }) async {
    return _evaluateActivity(
      endpoint: 'sequence',
      activityName: 'Secuencias',
      data: {
        'user_sequence': userSequence,
        'correct_sequence': correctSequence,
        'time': time,
      },
      duration: Duration(seconds: time.toInt()),
    );
  }

  /// Evaluar actividad de espejo/simetría
  Future<ActivityResult?> evaluateMirror({
    required bool isSymmetric,
    required bool userAnswer,
    required double time,
  }) async {
    return _evaluateActivity(
      endpoint: 'mirror',
      activityName: 'Simetría',
      data: {
        'is_symmetric': isSymmetric,
        'user_answer': userAnswer,
        'time': time,
      },
      duration: Duration(seconds: time.toInt()),
    );
  }

  /// Evaluar actividad de ritmo
  Future<ActivityResult?> evaluateRhythm({
    required List<int> userPattern,
    required List<int> correctPattern,
    required double time,
  }) async {
    return _evaluateActivity(
      endpoint: 'rhythm',
      activityName: 'Ritmo',
      data: {
        'user_pattern': userPattern,
        'correct_pattern': correctPattern,
        'time': time,
      },
      duration: Duration(seconds: time.toInt()),
    );
  }

  /// Evaluar actividad de velocidad
  Future<ActivityResult?> evaluateSpeed({
    required int wordsRead,
    required double time,
    required double comprehension,
  }) async {
    return _evaluateActivity(
      endpoint: 'speed',
      activityName: 'Velocidad',
      data: {
        'words_read': wordsRead,
        'time': time,
        'comprehension': comprehension,
      },
      duration: Duration(seconds: time.toInt()),
    );
  }

  /// Evaluar actividad de memoria
  Future<ActivityResult?> evaluateMemory({
    required List<String> userSequence,
    required List<String> correctSequence,
    required int attempts,
  }) async {
    return _evaluateActivity(
      endpoint: 'memory',
      activityName: 'Memoria',
      data: {
        'user_sequence': userSequence,
        'correct_sequence': correctSequence,
        'attempts': attempts,
      },
      duration: const Duration(seconds: 30), // Estimado
    );
  }

  /// Evaluar actividad de texto (PLN)
  Future<ActivityResult?> evaluateText({
    required String spokenText,
    required String correctText,
  }) async {
    return _evaluateActivity(
      endpoint: 'text',
      activityName: 'Lenguaje',
      data: {'spoken_text': spokenText, 'correct_text': correctText},
      duration: const Duration(seconds: 60), // Estimado
    );
  }

  /// Evaluar todas las actividades completadas (FORMATO CORRECTO BACKEND)
  ///
  /// Envía datos de las 5 actividades al endpoint /api/activities/rounds/evaluate
  /// Retorna predicción SÍ/NO, probabilidad %, nivel de riesgo
  Future<Map<String, dynamic>?> evaluateAllActivities({
    required Map<String, dynamic> userData,
    required List<ActivityRoundResult> completedActivities,
  }) async {
    try {
      _logger.i(
        'Enviando ${completedActivities.length} actividades al backend...',
      );

      // Construir formato esperado por el backend
      final requestData = {
        'user': {
          'gender': userData['gender'] ?? 'Male',
          'age': userData['age'] ?? 8,
          'native_lang': userData['native_lang'] ?? true,
          'other_lang': userData['other_lang'] ?? false,
        },
        'activities': completedActivities.map((activity) {
          return {
            'name': activity.activityId,
            'rounds': activity.rounds.map((round) {
              return {
                'clicks': round.clicks,
                'hits': round.hits,
                'misses': round.misses,
                'score': round.score,
                'accuracy': round.accuracy,
                'missrate': round.missrate,
              };
            }).toList(),
          };
        }).toList(),
      };

      _logger.d('Request data: ${jsonEncode(requestData)}');

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/activities/rounds/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.i('Respuesta del backend: ${responseData['data']}');

        return responseData['data'];
      } else {
        _logger.e(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error evaluando actividades: $e');
      return null;
    }
  }

  /// Método privado genérico para evaluar actividades
  Future<ActivityResult?> _evaluateActivity({
    required String endpoint,
    required String activityName,
    required Map<String, dynamic> data,
    required Duration duration,
  }) async {
    try {
      _logger.i('Evaluating $activityName activity...');

      final response = await http
          .post(
            Uri.parse(
              '${AppConstants.apiBaseUrl}/activities/$endpoint/evaluate',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final resultData = responseData['data'];

        _logger.i('$activityName evaluated: ${resultData["result"]}');

        return ActivityResult(
          activityId: endpoint,
          activityName: activityName,
          timestamp: DateTime.now(),
          result: resultData['result'],
          probability: resultData['probability'].toDouble(),
          confidence: resultData['confidence'].toDouble(),
          details: resultData['details'] ?? {},
          duration: duration,
        );
      } else {
        _logger.e('Error response: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error evaluating $activityName: $e');
      return null;
    }
  }
}
