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
    String? userId,
    String? childId,
    String? userName,
    String? childName,
  }) async {
    try {
      _logger.i(
        'Enviando ${completedActivities.length} actividades al backend...',
      );

      // Construir formato esperado por el backend
      final requestData = {
        'userId': userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        'childId': childId,
        'userName': userName ?? 'Usuario Tablet',
        'childName': childName ?? 'Niño',
        'childAge': userData['age'] ?? 8, // Edad del niño
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

      _logger.i('📤 Enviando al backend:');
      _logger.i('   User: ${requestData['user']}');
      _logger.i('   Activities: ${(requestData['activities'] as List).length}');
      for (var activity in (requestData['activities'] as List)) {
        _logger.i(
          '   - ${activity['name']}: ${(activity['rounds'] as List).length} rondas',
        );
      }
      _logger.d('Request completo: ${jsonEncode(requestData)}');

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

  /// Sincronizar nuevo usuario (tutor) con el backend
  Future<bool> syncUserToBackend({
    required String userId,
    required String userName,
    required int age,
  }) async {
    try {
      _logger.i('📤 Sincronizando usuario al backend: $userName');

      final userData = {
        'id': userId,
        'name': userName,
        'age': age,
        'gender': 'Male',
        'native_lang': true,
        'other_lang': false,
      };

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('✅ Usuario sincronizado correctamente al backend');
        return true;
      } else {
        _logger.w('⚠️ Error al sincronizar usuario: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sincronizando usuario al backend: $e');
      return false;
    }
  }

  /// Sincronizar nuevo niño (child) con el backend
  Future<bool> syncChildToBackend({
    required String childId,
    required String tutorId,
    required String childName,
    required int childAge,
  }) async {
    try {
      _logger.i('📤 Sincronizando niño al backend: $childName');

      final childData = {
        'id': childId,
        'user_id': tutorId,
        'name': childName,
        'age': childAge,
        'gender': 'Male',
      };

      _logger.i('📊 Datos enviados: $childData');

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/children'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(childData),
          )
          .timeout(AppConstants.apiTimeout);

      _logger.i('📨 Respuesta del servidor: ${response.statusCode}');
      _logger.i('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('✅ Niño sincronizado correctamente al backend');
        return true;
      } else {
        _logger.w(
          '⚠️ Error al sincronizar niño: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error sincronizando niño al backend: $e');
      return false;
    }
  }
}
