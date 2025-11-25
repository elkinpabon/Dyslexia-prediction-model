import 'package:flutter/material.dart';
import '../../../services/audio/audio_service.dart';

class ScreeningModals {
  // Colores principales
  static const Color _primaryColor = Color(0xFF2E5090);
  static const Color _accentColor = Color(0xFF4CAF50);

  static Future<void> showWelcomeModal(
    BuildContext context,
    AudioService audioService,
  ) async {
    // Reproducir audio automáticamente al abrir el modal
    await audioService.speak(
      'Vamos a hacer algunas actividades divertidas para ver cómo lees y escuchas. '
      'No te preocupes, no hay respuestas correctas o incorrectas. '
      'Solo haz lo mejor que puedas y diviértete.',
    );

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

                  // Descripción con puntos
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint(
                          icon: Icons.play_circle,
                          text:
                              'Vamos a hacer algunas actividades divertidas para ver cómo lees y escuchas.',
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                          icon: Icons.favorite,
                          text:
                              'No hay respuestas correctas o incorrectas - solo haz lo mejor que puedas.',
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                          icon: Icons.sentiment_satisfied,
                          text: '¡Diviértete y disfruta el proceso!',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botones
                  Row(
                    children: [
                      // Botón Escuchar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            audioService.speak(
                              'Vamos a hacer algunas actividades divertidas para ver cómo lees y escuchas. '
                              'No te preocupes, no hay respuestas correctas o incorrectas. '
                              'Solo haz lo mejor que puedas y diviértete.',
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

                      // Botón Continuar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle, size: 22),
                          label: const Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _primaryColor,
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

  static Future<void> showActivityModal(
    BuildContext context,
    AudioService audioService, {
    required int activityNumber,
    required String activityType,
  }) async {
    final description = ActivityDescriptions.getDescription(
      activityNumber,
      activityType,
    );

    // Obtener icono y color según tipo de actividad
    final icon = _getActivityIcon(activityType);
    final color = _getActivityColor(activityType);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ActivityInstructionsModal(
        description: description,
        icon: icon,
        color: color,
        activityNumber: activityNumber,
        audioService: audioService,
      ),
    );
  }

  // Modal de instrucciones de actividad (StatefulWidget para manejar audio)
  static Widget _ActivityInstructionsModal({
    required Map<String, String> description,
    required IconData icon,
    required Color color,
    required int activityNumber,
    required AudioService audioService,
  }) {
    return _ActivityInstructionsModalWidget(
      description: description,
      icon: icon,
      color: color,
      activityNumber: activityNumber,
      audioService: audioService,
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

  // Construir un punto de viñeta con icono
  static Widget _buildBulletPoint({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
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
        return _wrongLetterDescriptions[taskNumber] ?? _defaultDescription();

      case 'complete_word':
        return _completeWordDescriptions[taskNumber] ?? _defaultDescription();

      default:
        return _defaultDescription();
    }
  }

  static Map<String, String> _defaultDescription() {
    return {
      'simple': 'Nueva actividad',
      'detailed':
          'Realiza esta actividad lo mejor que puedas. Si tienes dudas, puedes escuchar las instrucciones de nuevo.',
      'voice':
          'Realiza esta actividad lo mejor que puedas. Si tienes dudas, puedes escuchar las instrucciones de nuevo.',
    };
  }

  static final Map<int, Map<String, String>>
  _visualDiscriminationDescriptions = {
    0: {
      'simple': 'Discriminación Visual - Nivel 1',
      'detailed':
          'Vas a ver dos imágenes. Necesitas encontrar qué es diferente entre ellas. '
          'Toca la diferencia que veas. No hay límite de tiempo, así que observa con cuidado.',
      'voice':
          'Vas a ver dos imágenes. Necesitas encontrar qué es diferente entre ellas. '
          'Toca la diferencia que veas. No hay límite de tiempo, así que observa con cuidado.',
    },
    1: {
      'simple': 'Discriminación Visual - Nivel 2',
      'detailed':
          'Ahora las diferencias serán más pequeñas. Mira cuidadosamente cada detalle de las dos imágenes. '
          'Cuando encuentres qué es diferente, toca en ese lugar.',
      'voice':
          'Ahora las diferencias serán más pequeñas. Mira cuidadosamente cada detalle de las dos imágenes. '
          'Cuando encuentres qué es diferente, toca en ese lugar.',
    },
    2: {
      'simple': 'Discriminación Visual - Nivel 3',
      'detailed':
          'Las diferencias son ahora muy pequeñas. Necesitarás observar con mucha atención todos los detalles. '
          'Toma tu tiempo y observa bien antes de tocar.',
      'voice':
          'Las diferencias son ahora muy pequeñas. Necesitarás observar con mucha atención todos los detalles. '
          'Toma tu tiempo y observa bien antes de tocar.',
    },
    3: {
      'simple': 'Discriminación Visual - Nivel 4',
      'detailed':
          'Esta es la versión más difícil. Las diferencias son muy sutiles. Observa cada parte cuidadosamente. '
          'Si no encuentras la diferencia enseguida, no te rindas, sigue buscando.',
      'voice':
          'Esta es la versión más difícil. Las diferencias son muy sutiles. Observa cada parte cuidadosamente. '
          'Si no encuentras la diferencia enseguida, no te rindas, sigue buscando.',
    },
  };

  static final Map<int, Map<String, String>> _auditoryDescriptions = {
    8: {
      'simple': 'Tareas Auditivas - Nivel 1',
      'detailed':
          'Vas a escuchar una palabra o sonido. Después, escucharás varias opciones. '
          'Debes seleccionar cuál de las opciones es igual a lo que escuchaste primero.',
      'voice':
          'Vas a escuchar una palabra o sonido. Después, escucharás varias opciones. '
          'Debes seleccionar cuál de las opciones es igual a lo que escuchaste primero.',
    },
    9: {
      'simple': 'Tareas Auditivas - Nivel 2',
      'detailed':
          'Escucharás dos palabras muy parecidas. Necesitas decir si suenan igual o diferentes. '
          'Escucha con atención porque los sonidos son muy similares.',
      'voice':
          'Escucharás dos palabras muy parecidas. Necesitas decir si suenan igual o diferentes. '
          'Escucha con atención porque los sonidos son muy similares.',
    },
  };

  static final Map<int, Map<String, String>> _memoryDescriptions = {
    16: {
      'simple': 'Memoria Secuencial - Nivel 1',
      'detailed':
          'Vas a ver una serie de números en orden. Tienes que recordar ese orden. '
          'Después, debes tocar los números en el mismo orden que los viste.',
      'voice':
          'Vas a ver una serie de números en orden. Tienes que recordar ese orden. '
          'Después, debes tocar los números en el mismo orden que los viste.',
    },
    17: {
      'simple': 'Memoria Secuencial - Nivel 2',
      'detailed':
          'Ahora habrá más números y tendrás que recordar un orden más largo. '
          'Observa cuidadosamente y trata de memorizar la secuencia completa.',
      'voice':
          'Ahora habrá más números y tendrás que recordar un orden más largo. '
          'Observa cuidadosamente y trata de memorizar la secuencia completa.',
    },
  };

  static final Map<int, Map<String, String>> _dictationDescriptions = {
    24: {
      'simple': 'Dictado - Nivel 1',
      'detailed':
          'Escucharás una palabra. Luego debes escribirla en el teclado lo mejor que puedas. '
          'No te preocupes si cometes errores, solo intenta escribir lo que escuchaste.',
      'voice':
          'Escucharás una palabra. Luego debes escribirla en el teclado lo mejor que puedas. '
          'No te preocupes si cometes errores, solo intenta escribir lo que escuchaste.',
    },
    25: {
      'simple': 'Dictado - Nivel 2',
      'detailed':
          'Ahora escucharás frases completas. Escucha con cuidado y escribe lo que oyes. '
          'Puedes escuchar la frase de nuevo si lo necesitas.',
      'voice':
          'Ahora escucharás frases completas. Escucha con cuidado y escribe lo que oyes. '
          'Puedes escuchar la frase de nuevo si lo necesitas.',
    },
  };

  static final Map<int, Map<String, String>> _speedDescriptions = {
    32: {
      'simple': 'Velocidad y Gramática - Nivel 1',
      'detailed':
          'Vas a ver palabras que aparecerán rápidamente. Necesitas leerlas lo más rápido que puedas. '
          'Toca cada palabra después de leerla.',
      'voice':
          'Vas a ver palabras que aparecerán rápidamente. Necesitas leerlas lo más rápido que puedas. '
          'Toca cada palabra después de leerla.',
    },
    33: {
      'simple': 'Velocidad y Gramática - Nivel 2',
      'detailed':
          'Las palabras aparecerán más rápido esta vez. Lee lo más rápido que puedas '
          'y toca cuando hayas leído la palabra.',
      'voice':
          'Las palabras aparecerán más rápido esta vez. Lee lo más rápido que puedas '
          'y toca cuando hayas leído la palabra.',
    },
  };

  static final Map<int, Map<String, String>> _wrongLetterDescriptions = {
    36: {
      'simple': 'Identificar Letra Incorrecta - Nivel 1',
      'detailed':
          'Vas a ver palabras. Una letra en cada palabra está equivocada. '
          'Debes encontrar y tocar la letra que no pertenece a esa palabra.',
      'voice':
          'Vas a ver palabras. Una letra en cada palabra está equivocada. '
          'Debes encontrar y tocar la letra que no pertenece a esa palabra.',
    },
    37: {
      'simple': 'Identificar Letra Incorrecta - Nivel 2',
      'detailed':
          'Las palabras son más difíciles ahora. Busca cuidadosamente cuál letra está mal. '
          'A veces puede ser muy parecida a la letra correcta.',
      'voice':
          'Las palabras son más difíciles ahora. Busca cuidadosamente cuál letra está mal. '
          'A veces puede ser muy parecida a la letra correcta.',
    },
  };

  static final Map<int, Map<String, String>> _completeWordDescriptions = {
    42: {
      'simple': 'Completar Palabra - Nivel 1',
      'detailed':
          'Vas a ver palabras incompletas. Falta una o más letras. '
          'Tú debes escribir la palabra completa en el teclado.',
      'voice':
          'Vas a ver palabras incompletas. Falta una o más letras. '
          'Tú debes escribir la palabra completa en el teclado.',
    },
    43: {
      'simple': 'Completar Palabra - Nivel 2',
      'detailed':
          'Ahora las palabras serán más largas y faltan más letras. '
          'Piensa bien y escribe la palabra completa.',
      'voice':
          'Ahora las palabras serán más largas y faltan más letras. '
          'Piensa bien y escribe la palabra completa.',
    },
  };
}

/// Widget stateful para modal de instrucciones que maneja audio
class _ActivityInstructionsModalWidget extends StatefulWidget {
  final Map<String, String> description;
  final IconData icon;
  final Color color;
  final int activityNumber;
  final AudioService audioService;

  const _ActivityInstructionsModalWidget({
    required this.description,
    required this.icon,
    required this.color,
    required this.activityNumber,
    required this.audioService,
  });

  @override
  State<_ActivityInstructionsModalWidget> createState() =>
      _ActivityInstructionsModalWidgetState();
}

class _ActivityInstructionsModalWidgetState
    extends State<_ActivityInstructionsModalWidget> {
  @override
  void initState() {
    super.initState();
    // Reproducir audio automáticamente al abrir el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.audioService.speak(widget.description['voice']!);
    });
  }

  @override
  void dispose() {
    // Detener el audio cuando se cierre el modal
    widget.audioService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
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
                // Badge de número de actividad
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
                    'Actividad ${widget.activityNumber + 1} de 48',
                    style: const TextStyle(
                      fontSize: 12,
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
                  child: Icon(widget.icon, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Título de actividad
                Text(
                  widget.description['simple']!,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Descripción detallada en puntos
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
                    widget.description['detailed']!,
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
                    // Botón Escuchar
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await widget.audioService.speak(
                            widget.description['voice']!,
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
                          backgroundColor: ScreeningModals._accentColor,
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

                    // Botón Empezar
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Detener el audio antes de cerrar
                          widget.audioService.stopSpeaking();
                          Navigator.pop(context);
                        },
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
                          foregroundColor: widget.color,
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
    );
  }
}
