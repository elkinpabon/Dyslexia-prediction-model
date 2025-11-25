import 'package:flutter/material.dart';
import '../../../../services/audio/openai_tts_service.dart';

class ScreeningModals {
  // Colores principales
  static const Color _primaryColor = Color(0xFF2E5090);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFFA500);
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  static Future<void> showWelcomeModal(
    BuildContext context,
    OpenAiTtsService ttsService,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono principal
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Vamos a hacer algunas actividades divertidas para ver cómo lees y escuchas.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No te preocupes, no hay respuestas correctas o incorrectas. Solo haz lo mejor que puedas y ¡diviértete!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón Aceptar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ttsService.speak(
                          'Vamos a hacer algunas actividades divertidas para ver cómo lees y escuchas. '
                          'No te preocupes, no hay respuestas correctas o incorrectas. '
                          'Solo haz lo mejor que puedas y diviértete.',
                          waitForCompletion: false,
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text(
                        'Aceptar y comenzar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showActivityModal(
    BuildContext context,
    OpenAiTtsService ttsService, {
    required int activityNumber,
    required String activityType,
  }) async {
    final description = ActivityDescriptions.getDescription(
      activityNumber,
      activityType,
    );

    // Obtener icono según tipo de actividad
    final icon = _getActivityIcon(activityType);
    final color = _getActivityColor(activityType);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número de actividad
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Actividad ${activityNumber + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Icono grande
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(icon, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Título de actividad
                  Text(
                    description['simple']!,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Descripción detallada
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      description['detailed']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botones de acción
                  Row(
                    children: [
                      // Botón Volver a escuchar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ttsService.speak(
                              description['voice']!,
                              waitForCompletion: false,
                            );
                          },
                          icon: const Icon(Icons.volume_up, size: 22),
                          label: const Text(
                            'Escuchar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón Entendido
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle, size: 22),
                          label: const Text(
                            'Empezar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Obtener icono según tipo de actividad
  static IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'visual_discrimination':
        return Icons.remove_red_eye;
      case 'auditory':
        return Icons.hearing;
      case 'memory_sequential':
        return Icons.psychology;
      case 'dictation':
        return Icons.edit_note;
      case 'speed_grammar':
        return Icons.speed;
      case 'identify_wrong_letter':
        return Icons.search;
      case 'complete_word':
        return Icons.auto_fix_high;
      default:
        return Icons.star;
    }
  }

  // Obtener color según tipo de actividad
  static Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'visual_discrimination':
        return const Color(0xFF1976D2); // Azul
      case 'auditory':
        return const Color(0xFFD32F2F); // Rojo
      case 'memory_sequential':
        return const Color(0xFF388E3C); // Verde
      case 'dictation':
        return const Color(0xFF7B1FA2); // Púrpura
      case 'speed_grammar':
        return const Color(0xFFF57C00); // Naranja
      case 'identify_wrong_letter':
        return const Color(0xFF0097A7); // Cian
      case 'complete_word':
        return const Color(0xFFE91E63); // Rosa
      default:
        return _primaryColor;
    }
  }
}

class ActivityDescriptions {
  static Map<String, String> getDescription(
    int taskNumber,
    String activityType,
  ) {
    switch (activityType) {
      case 'visual_discrimination':
        return _visualDiscriminationDescriptions[taskNumber] ??
            _defaultDescription();

      case 'auditory':
        return _auditoryDescriptions[taskNumber] ?? _defaultDescription();

      case 'memory_sequential':
        return _memoryDescriptions[taskNumber] ?? _defaultDescription();

      case 'dictation':
        return _dictationDescriptions[taskNumber] ?? _defaultDescription();

      case 'speed_grammar':
        return _speedDescriptions[taskNumber] ?? _defaultDescription();

      case 'identify_wrong_letter':
        return _identifyWrongLetterDescriptions[taskNumber] ??
            _defaultDescription();

      case 'complete_word':
        return _completeWordDescriptions[taskNumber] ?? _defaultDescription();

      default:
        return _defaultDescription();
    }
  }

  static Map<String, String> _defaultDescription() => {
    'simple': 'Nueva Actividad',
    'detailed':
        'En esta actividad deberás seguir las instrucciones que se te indiquen.',
    'voice':
        'En esta actividad deberás seguir las instrucciones que se te indiquen.',
  };

  static const Map<int, Map<String, String>>
  _visualDiscriminationDescriptions = {
    0: {
      'simple': 'Discriminación Visual',
      'detailed':
          'Debes encontrar la letra que buscas entre varias opciones. Elige la que coincida exactamente con la que te muestro.',
      'voice':
          'Debes encontrar la letra que buscas entre varias opciones. Elige la que coincida exactamente con la que te muestro.',
    },
  };

  static const Map<int, Map<String, String>> _auditoryDescriptions = {
    8: {
      'simple': 'Discriminación Auditiva',
      'detailed':
          'Escucharás sonidos de letras. Debes identificar qué letra escuchas y hacer clic en ella.',
      'voice':
          'Escucharás sonidos de letras. Debes identificar qué letra escuchas y hacer clic en ella.',
    },
  };

  static const Map<int, Map<String, String>> _memoryDescriptions = {
    16: {
      'simple': 'Memoria Secuencial',
      'detailed':
          'Se te mostrará una secuencia de letras. Debes recordarla y escribirla en el mismo orden cuando se te pida.',
      'voice':
          'Se te mostrará una secuencia de letras. Debes recordarla y escribirla en el mismo orden cuando se te pida.',
    },
  };

  static const Map<int, Map<String, String>> _dictationDescriptions = {
    24: {
      'simple': 'Dictado',
      'detailed':
          'Escucharás palabras. Debes escribirlas correctamente. ¡Escucha con atención!',
      'voice':
          'Escucharás palabras. Debes escribirlas correctamente. ¡Escucha con atención!',
    },
  };

  static const Map<int, Map<String, String>> _speedDescriptions = {
    32: {
      'simple': 'Velocidad y Gramática',
      'detailed':
          'Lee las palabras lo más rápido que puedas. El tiempo es importante en esta actividad.',
      'voice':
          'Lee las palabras lo más rápido que puedas. El tiempo es importante en esta actividad.',
    },
  };

  static const Map<int, Map<String, String>>
  _identifyWrongLetterDescriptions = {
    36: {
      'simple': 'Identificar Letra Incorrecta',
      'detailed':
          'Verás grupos de letras con una incorrecta. ¡Encuentrala lo más rápido que puedas!',
      'voice':
          'Verás grupos de letras con una incorrecta. ¡Encuentrala lo más rápido que puedas!',
    },
  };

  static const Map<int, Map<String, String>> _completeWordDescriptions = {
    42: {
      'simple': 'Completar Palabras',
      'detailed':
          'Se te muestran palabras incompletas. Debes llenar el espacio con la letra que falta.',
      'voice':
          'Se te muestran palabras incompletas. Debes llenar el espacio con la letra que falta.',
    },
  };
}
