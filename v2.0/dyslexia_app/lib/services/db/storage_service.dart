import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../constants/app_constants.dart';
import '../../models/activity_result.dart';
import '../../models/user_profile.dart';
import '../../models/app_statistics.dart';

/// Servicio de almacenamiento local persistente
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _logger = Logger();
  SharedPreferences? _prefs;

  /// Inicializar SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _logger.i('Storage service initialized');
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  // ==================== USER PROFILE ====================

  /// Guardar perfil de usuario
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final json = jsonEncode(profile.toJson());
      final success = await prefs.setString(AppConstants.keyUserProfile, json);
      _logger.i('User profile saved: ${profile.name}');
      return success;
    } catch (e) {
      _logger.e('Error saving user profile: $e');
      return false;
    }
  }

  /// Obtener perfil de usuario
  UserProfile? getUserProfile() {
    try {
      final json = prefs.getString(AppConstants.keyUserProfile);
      if (json == null) return null;

      return UserProfile.fromJson(jsonDecode(json));
    } catch (e) {
      _logger.e('Error loading user profile: $e');
      return null;
    }
  }

  /// Verificar si existe perfil
  bool hasUserProfile() => prefs.containsKey(AppConstants.keyUserProfile);

  // ==================== ACTIVITY HISTORY ====================

  /// Guardar resultado de actividad
  Future<bool> saveActivityResult(ActivityResult result) async {
    try {
      final history = getActivityHistory();
      history.add(result);

      // Mantener solo los últimos 100 resultados
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }

      final json = jsonEncode(history.map((r) => r.toJson()).toList());
      final success = await prefs.setString(
        AppConstants.keyActivityHistory,
        json,
      );

      _logger.i('Activity result saved: ${result.activityName}');

      // Actualizar estadísticas
      await _updateStatistics();

      return success;
    } catch (e) {
      _logger.e('Error saving activity result: $e');
      return false;
    }
  }

  /// Obtener historial de actividades
  List<ActivityResult> getActivityHistory() {
    try {
      final json = prefs.getString(AppConstants.keyActivityHistory);
      if (json == null) return [];

      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => ActivityResult.fromJson(item)).toList();
    } catch (e) {
      _logger.e('Error loading activity history: $e');
      return [];
    }
  }

  /// Obtener historial filtrado por actividad
  List<ActivityResult> getActivityHistoryByType(String activityId) {
    return getActivityHistory()
        .where((result) => result.activityId == activityId)
        .toList();
  }

  /// Limpiar historial
  Future<bool> clearActivityHistory() async {
    try {
      await prefs.remove(AppConstants.keyActivityHistory);
      await _updateStatistics();
      _logger.i('Activity history cleared');
      return true;
    } catch (e) {
      _logger.e('Error clearing history: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

  /// Actualizar estadísticas
  Future<void> _updateStatistics() async {
    try {
      final history = getActivityHistory();
      final stats = AppStatistics.fromResults(history);

      final json = jsonEncode(stats.toJson());
      await prefs.setString(AppConstants.keyStatistics, json);

      _logger.i('Statistics updated');
    } catch (e) {
      _logger.e('Error updating statistics: $e');
    }
  }

  /// Obtener estadísticas
  AppStatistics getStatistics() {
    try {
      final json = prefs.getString(AppConstants.keyStatistics);
      if (json == null) {
        return AppStatistics.fromResults(getActivityHistory());
      }

      return AppStatistics.fromJson(jsonDecode(json));
    } catch (e) {
      _logger.e('Error loading statistics: $e');
      return AppStatistics.fromResults(getActivityHistory());
    }
  }

  // ==================== SETTINGS ====================

  /// Verificar si es el primer lanzamiento
  bool isFirstLaunch() {
    return !prefs.containsKey(AppConstants.keyFirstLaunch);
  }

  /// Marcar como lanzado
  Future<void> markAsLaunched() async {
    await prefs.setBool(AppConstants.keyFirstLaunch, false);
  }

  /// Configuración de sonido
  bool isSoundEnabled() => prefs.getBool(AppConstants.keySoundEnabled) ?? true;

  Future<void> setSoundEnabled(bool enabled) async {
    await prefs.setBool(AppConstants.keySoundEnabled, enabled);
  }

  /// Configuración de voz
  bool isVoiceEnabled() => prefs.getBool(AppConstants.keyVoiceEnabled) ?? true;

  Future<void> setVoiceEnabled(bool enabled) async {
    await prefs.setBool(AppConstants.keyVoiceEnabled, enabled);
  }

  // ==================== CHILD PROFILE SELECTION ====================

  /// Obtener ID del niño seleccionado
  String? getSelectedChildId() {
    return prefs.getString('selected_child_id');
  }

  /// Guardar ID del niño seleccionado
  Future<void> setSelectedChildId(String childId) async {
    await prefs.setString('selected_child_id', childId);
  }

  /// Limpiar selección de niño
  Future<void> clearSelectedChild() async {
    await prefs.remove('selected_child_id');
  }

  // ==================== CLEAR ALL ====================

  /// Limpiar todos los datos
  Future<bool> clearAll() async {
    try {
      await prefs.clear();
      _logger.i('All data cleared');
      return true;
    } catch (e) {
      _logger.e('Error clearing all data: $e');
      return false;
    }
  }
}
