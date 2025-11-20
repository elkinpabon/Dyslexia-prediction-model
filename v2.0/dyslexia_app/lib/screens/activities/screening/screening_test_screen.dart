import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../../models/round_data.dart';
import '../../../services/audio/audio_service.dart';
import '../../../widgets/loading_overlay.dart';
import '../../results/round_results_screen.dart';

class ScreeningTestScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const ScreeningTestScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<ScreeningTestScreen> createState() => _ScreeningTestScreenState();
}

class _ScreeningTestScreenState extends State<ScreeningTestScreen>
    with SingleTickerProviderStateMixin {
  int _currentTask = 0;
  final List<RoundData> _completedRounds = [];
  DateTime? _sessionStartTime;
  DateTime? _taskStartTime;
  bool _isProcessing = false;

  // Métricas avanzadas de la tarea actual
  int _currentClicks = 0;
  int _currentHits = 0;
  int _currentMisses = 0;
  final List<int> _reactionTimes = []; // Milisegundos por click
  // int _hesitationCount = 0; // Clicks sin progreso (para futuras versiones)

  // Estado de la tarea actual
  dynamic _taskState;
  final Random _random = Random();

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Feedback visual
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _taskStartTime = DateTime.now();

    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _initializeTask();
    _animationController.forward();

    // Mostrar modal de bienvenida después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showWelcomeDialog() async {
    if (!mounted) return;

    final audioService = context.read<AudioService>();

    // Reproducir mensaje de bienvenida con información sobre el test
    audioService.speak(
      'Bienvenido al test de cribado para dislexia. '
      'Este test evalúa patrones de respuesta en diferentes áreas como discriminación visual, '
      'memoria secuencial, y procesamiento auditivo. '
      'Realizarás 48 tareas cortas con dificultad progresiva. '
      'No hay respuestas correctas o incorrectas, solo responde naturalmente. '
      'Lee las instrucciones en pantalla.',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _WelcomeDialogWithTimer(audioService: audioService);
      },
    );
  }

  void _initializeTask() {
    _currentClicks = 0;
    _currentHits = 0;
    _currentMisses = 0;
    _reactionTimes.clear();
    _taskStartTime = DateTime.now();
    _showFeedback = false;

    if (_currentTask < 8) {
      _initVisualTask();
      if (_currentTask == 0) {
        _speakTaskInstruction(
          'Comenzamos con tareas de discriminación visual. '
          'Debes encontrar y tocar la letra que te pido entre varias opciones similares.',
        );
      }
    } else if (_currentTask < 16) {
      _initAuditoryTask();
      if (_currentTask == 8) {
        _speakTaskInstruction(
          'Ahora vamos con tareas auditivas. '
          'Escucha la letra que pronuncio y selecciona la correcta.',
        );
      }
    } else if (_currentTask < 24) {
      _initMemoryTask();
      if (_currentTask == 16) {
        _speakTaskInstruction(
          'Tareas de memoria secuencial. '
          'Memoriza la secuencia de letras que te muestro y luego repítela.',
        );
      }
    } else if (_currentTask < 32) {
      _initDictationTask();
      if (_currentTask == 24) {
        _speakTaskInstruction(
          'Ejercicios de dictado. '
          'Escucha la palabra y escríbela correctamente.',
        );
      }
    } else if (_currentTask < 36) {
      _initSpeedTask();
      if (_currentTask == 32) {
        _speakTaskInstruction(
          'Tareas de velocidad y gramática. '
          'Lee rápidamente e identifica si hay errores.',
        );
      }
    } else if (_currentTask < 42) {
      _initIdentifyWrongLetterTask();
      if (_currentTask == 36) {
        _speakTaskInstruction(
          'Encuentra la letra incorrecta. '
          'Una letra no encaja, identifícala.',
        );
      }
    } else {
      _initCompleteWordTask();
      if (_currentTask == 42) {
        _speakTaskInstruction(
          'Completa la palabra. '
          'Falta una letra, selecciona la correcta.',
        );
      }
    }
  }

  void _speakTaskInstruction(String instruction) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final audioService = context.read<AudioService>();
        audioService.speak(instruction);
      }
    });
  }

  void _initVisualTask() {
    final visualTasks = [
      // Nivel 1: 3x2 (6 letras) - Fácil
      {
        'target': 'b',
        'distractor': 'd',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 2, 'cols': 3},
        'difficulty': 1,
      },
      // Nivel 2: 3x3 (9 letras)
      {
        'target': 'd',
        'distractor': 'b',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 3, 'cols': 3},
        'difficulty': 2,
      },
      // Nivel 3: 4x3 (12 letras)
      {
        'target': 'p',
        'distractor': 'q',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 3, 'cols': 4},
        'difficulty': 3,
      },
      // Nivel 4: 4x4 (16 letras)
      {
        'target': 'q',
        'distractor': 'p',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 4, 'cols': 4},
        'difficulty': 4,
      },
      // Nivel 5: 5x4 (20 letras)
      {
        'target': 'm',
        'distractor': 'n',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 4, 'cols': 5},
        'difficulty': 5,
      },
      // Nivel 6: 5x5 (25 letras)
      {
        'target': 'n',
        'distractor': 'm',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 5, 'cols': 5},
        'difficulty': 6,
      },
      // Nivel 7: 6x5 (30 letras) - Difícil
      {
        'target': 'u',
        'distractor': 'n',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 5, 'cols': 6},
        'difficulty': 7,
      },
      // Nivel 8: 6x6 (36 letras) - Muy difícil
      {
        'target': 'b',
        'distractor': 'p',
        'instruction': 'Encuentra la letra que buscas',
        'gridSize': {'rows': 6, 'cols': 6},
        'difficulty': 8,
      },
    ];
    _taskState = visualTasks[_currentTask % 8];
  }

  void _handleVisualTap(String selected) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final isCorrect = selected == _taskState['target'];

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar (sin feedback de correcto/incorrecto)
    await _completeTask();
  }

  Widget _buildVisualTask() {
    final target = _taskState['target'] as String;
    final distractor = _taskState['distractor'] as String;
    final instruction = _taskState['instruction'] as String;
    final gridSize = _taskState['gridSize'] as Map;
    final rows = gridSize['rows'] as int;
    final cols = gridSize['cols'] as int;

    // Generar cuadrícula con letras aleatorias
    final totalCells = rows * cols;
    final letters = <String>[];

    // Añadir target y distractores
    letters.add(target); // Una letra objetivo
    final distractorCount = (totalCells * 0.7).toInt(); // 70% distractores
    for (int i = 0; i < distractorCount && letters.length < totalCells; i++) {
      letters.add(distractor);
    }

    // Rellenar con letras aleatorias similares
    final fillerLetters = [target, distractor, 'o', 'a', 'e'];
    while (letters.length < totalCells) {
      letters.add(fillerLetters[_random.nextInt(fillerLetters.length)]);
    }

    // Mezclar
    letters.shuffle(_random);

    // Calcular tamaño de celda según filas para que quepa en pantalla
    final cellSize = rows <= 3
        ? 60.0
        : (rows == 4 ? 50.0 : (rows == 5 ? 42.0 : 36.0));
    final fontSize = rows <= 3
        ? 32.0
        : (rows == 4 ? 26.0 : (rows == 5 ? 22.0 : 18.0));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción compacta
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$instruction: "$target"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Cuadrícula de letras compacta
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: cols * (cellSize + 6), // 6 = spacing
              maxHeight: rows * (cellSize + 6),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final letter = letters[index];
                return Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _handleVisualTap(letter),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Ayuda contextual
        _buildHelpButton('Discriminación visual de letras similares'),
      ],
    );
  }

  // ========== TAREAS AUDITIVAS (9-16) ==========
  void _initAuditoryTask() {
    final auditoryTasks = [
      {
        'sound': 'be',
        'target': 'b',
        'options': ['b', 'd', 'p', 'q'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'de',
        'target': 'd',
        'options': ['d', 'b', 'q', 'p'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'pe',
        'target': 'p',
        'options': ['p', 'q', 'b', 'd'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'cu',
        'target': 'q',
        'options': ['q', 'p', 'd', 'b'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'eme',
        'target': 'm',
        'options': ['m', 'n', 'w', 'v'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'ene',
        'target': 'n',
        'options': ['n', 'm', 'ñ', 'u'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 'u',
        'target': 'u',
        'options': ['u', 'n', 'v', 'ü'],
        'instruction': 'Escucha y selecciona una letra',
      },
      {
        'sound': 've',
        'target': 'v',
        'options': ['v', 'b', 'w', 'u'],
        'instruction': 'Escucha y selecciona una letra',
      },
    ];
    _taskState = auditoryTasks[(_currentTask - 8) % 8];
    _taskState['played'] = false;

    // Aleatorizar opciones para evitar que siempre sea la primera
    final options = List<String>.from(_taskState['options'] as List);
    options.shuffle(_random);
    _taskState['options'] = options;
  }

  Future<void> _playAuditorySound() async {
    // Permitir reproducir cada vez que se presione el botón (sin restricción)
    setState(() {
      _taskState['played'] = true;
    });
    final audioService = context.read<AudioService>();
    // El servicio ya fuerza español internamente
    await audioService.speak(_taskState['sound']);
  }

  void _handleAuditoryTap(String selected) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final isCorrect = selected == _taskState['target'];

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar
    await _completeTask();
  }

  Widget _buildAuditoryTask() {
    final instruction = _taskState['instruction'] as String;
    final options = _taskState['options'] as List<String>;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hearing, color: Colors.purple.shade700, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.purple.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón de reproducción
              ElevatedButton.icon(
                onPressed: _playAuditorySound,
                icon: const Icon(Icons.volume_up, size: 32),
                label: Text(
                  _taskState['played'] == true
                      ? 'Reproducir de nuevo'
                      : 'Reproducir sonido',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Opciones de letras en cuadrícula 2x2
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: options.map((letter) {
              return Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _handleAuditoryTap(letter),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.purple.shade300,
                        width: 2.5,
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildHelpButton('Correspondencia sonido-letra'),
      ],
    );
  }

  // ========== TAREAS DE MEMORIA (16-23) - DIFICULTAD PROGRESIVA ==========
  void _initMemoryTask() {
    // Dificultad progresiva: 2, 2, 3, 3, 4, 4, 5, 5 elementos
    final sequenceLengths = [2, 2, 3, 3, 4, 4, 5, 5];
    final taskIndex = _currentTask - 16;
    final length = sequenceLengths[taskIndex % 8];

    // Todas las letras del alfabeto español (necesarias + distractoras)
    final allLetters = [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'ñ',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    ];
    allLetters.shuffle(_random);
    final sequence = allLetters.take(length).toList();

    _taskState = {
      'sequence': sequence,
      'length': length,
      'phase': 'showing', // 'showing', 'hidden', 'reproducing'
      'userInput': <String>[],
      'showingIndex': 0,
      'instruction': 'Memoriza la secuencia de $length letras',
      'difficulty': taskIndex + 1,
    };

    _startSequenceDisplay();
  }

  void _startSequenceDisplay() async {
    setState(() {
      _taskState['phase'] = 'showing';
      _taskState['showingIndex'] = 0;
    });

    final sequence = _taskState['sequence'] as List<String>;
    final audioService = context.read<AudioService>();

    await audioService.speak(_taskState['instruction']);

    // Tiempos reducidos para secuencia más ágil
    for (int i = 0; i < sequence.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 600),
      ); // Reducido de 800
      if (!mounted) return;
      setState(() {
        _taskState['showingIndex'] = i;
      });
      await audioService.speak(sequence[i]);
      await Future.delayed(
        const Duration(milliseconds: 900),
      ); // Reducido de 1200
    }

    await Future.delayed(const Duration(milliseconds: 400)); // Reducido de 500
    if (!mounted) return;

    setState(() {
      _taskState['phase'] = 'hidden';
    });

    await audioService.speak(
      'Ahora, reproduce la secuencia en el mismo orden.',
    );

    await Future.delayed(const Duration(milliseconds: 600)); // Reducido de 800
    if (!mounted) return;

    setState(() {
      _taskState['phase'] = 'reproducing';
    });
  }

  void _handleMemoryInput(String letter) async {
    if (_isProcessing || _taskState['phase'] != 'reproducing') return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final userInput = _taskState['userInput'] as List<String>;
    userInput.add(letter);

    final sequence = _taskState['sequence'] as List<String>;
    final currentIndex = userInput.length - 1;

    setState(() {});

    // Verificar si es correcto solo si no excedemos el tamaño de la secuencia
    if (currentIndex < sequence.length) {
      final isCorrect = letter == sequence[currentIndex];

      if (isCorrect) {
        _currentHits++;
      } else {
        _currentMisses++;
      }
    }

    // Si completó la secuencia (correcta o incorrectamente)
    if (userInput.length >= sequence.length) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _completeTask();
    }
  }

  Widget _buildMemoryTask() {
    final phase = _taskState['phase'] as String;
    final sequence = _taskState['sequence'] as List<String>;
    final userInput = _taskState['userInput'] as List<String>;
    final showingIndex = _taskState['showingIndex'] as int;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  phase == 'showing'
                      ? 'Observa y memoriza'
                      : phase == 'hidden'
                      ? 'Recuerda la secuencia...'
                      : 'Reproduce la secuencia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Área de secuencia
        if (phase == 'showing') ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(sequence.length, (index) {
                final isActive = index == showingIndex;
                final isPast = index < showingIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.orange.shade400
                          : isPast
                          ? Colors.orange.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? Colors.orange.shade700
                            : Colors.grey.shade400,
                        width: isActive ? 4 : 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.orange.shade300,
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      isPast || isActive ? sequence[index].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : isPast
                            ? Colors.orange.shade900
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ] else if (phase == 'hidden') ...[
          Container(
            width: 200,
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.orange.shade700,
            ),
          ),
        ] else ...[
          // Fase de reproducción
          Column(
            children: [
              // Input del usuario
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(sequence.length, (index) {
                    final hasInput = index < userInput.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: hasInput
                              ? Colors.orange.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasInput
                                ? Colors.orange.shade400
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          hasInput ? userInput[index].toUpperCase() : '',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Teclado de letras en cuadrícula compacta
              Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9, // 9 columnas para todas las letras
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: 27, // Total de letras del alfabeto español
                  itemBuilder: (context, index) {
                    final letters = [
                      'a',
                      'b',
                      'c',
                      'd',
                      'e',
                      'f',
                      'g',
                      'h',
                      'i',
                      'j',
                      'k',
                      'l',
                      'm',
                      'n',
                      'ñ',
                      'o',
                      'p',
                      'q',
                      'r',
                      's',
                      't',
                      'u',
                      'v',
                      'w',
                      'x',
                      'y',
                      'z',
                    ];
                    final letter = letters[index];
                    return Material(
                      color: Colors.white,
                      elevation: 3,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _handleMemoryInput(letter),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            letter.toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildHelpButton('Memoria secuencial de letras'),
      ],
    );
  }

  // ========== TAREAS DE DICTADO (24-31) - DIFICULTAD PROGRESIVA ==========
  void _initDictationTask() {
    final dictationWords = [
      // Nivel 1-2: Palabras cortas (3-4 letras)
      {
        'word': 'sol',
        'audio': 'sol',
        'options': ['sol', 'soul', 'sól', 'zol'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 1,
      },
      {
        'word': 'mar',
        'audio': 'mar',
        'options': ['mar', 'mal', 'már', 'nar'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 1,
      },
      // Nivel 3-4: Palabras medias (4-5 letras)
      {
        'word': 'casa',
        'audio': 'casa',
        'options': ['casa', 'caza', 'caca', 'cosa'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 2,
      },
      {
        'word': 'mesa',
        'audio': 'mesa',
        'options': ['mesa', 'meza', 'mésa', 'messa'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 2,
      },
      // Nivel 5-6: Palabras largas (5-6 letras)
      {
        'word': 'libro',
        'audio': 'libro',
        'options': ['libro', 'livro', 'libró', 'líbro'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 3,
      },
      {
        'word': 'perro',
        'audio': 'perro',
        'options': ['perro', 'pero', 'pérro', 'prero'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 3,
      },
      // Nivel 7-8: Palabras complejas (6-8 letras)
      {
        'word': 'mariposa',
        'audio': 'mariposa',
        'options': ['mariposa', 'maripoça', 'maribosa', 'maríposá'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 4,
      },
      {
        'word': 'elefante',
        'audio': 'elefante',
        'options': ['elefante', 'elefánte', 'elefanté', 'eléfante'],
        'instruction': 'Escucha y selecciona una opción',
        'difficulty': 4,
      },
    ];
    final taskIndex = _currentTask - 24;
    _taskState = dictationWords[taskIndex % 8];
    _taskState['played'] = false;
  }

  Future<void> _playDictationWord() async {
    if (_taskState['played'] == true) return;
    _taskState['played'] = true;
    final audioService = context.read<AudioService>();
    await audioService.speak(_taskState['audio']);
  }

  void _handleDictationTap(String selected) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final isCorrect = selected == _taskState['word'];

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar
    await _completeTask();
  }

  Widget _buildDictationTask() {
    final instruction = _taskState['instruction'] as String;
    final options = _taskState['options'] as List<String>;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade200, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spellcheck, color: Colors.teal.shade700, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón de reproducción
              ElevatedButton.icon(
                onPressed: _playDictationWord,
                icon: const Icon(Icons.volume_up, size: 32),
                label: Text(
                  _taskState['played'] == true
                      ? 'Escuchar de nuevo'
                      : 'Escuchar palabra',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Opciones de ortografía
        Column(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Material(
                color: Colors.white,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _handleDictationTap(option),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade300, width: 3),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildHelpButton('Reconocimiento ortográfico'),
      ],
    );
  }

  // ========== TAREAS DE VELOCIDAD (29-32) ==========
  void _initSpeedTask() {
    final speedSentences = [
      {
        'sentence': 'El perro come rápido en el jardín',
        'hasError': false,
        'instruction': 'Lee la oración y selecciona una opción',
      },
      {
        'sentence': 'La niña esta jugando con su muñeka',
        'hasError': true,
        'error': 'muñeka → muñeca',
        'instruction': 'Lee la oración y selecciona una opción',
      },
      {
        'sentence': 'Me gusta mucho leer libros interesantes',
        'hasError': false,
        'instruction': 'Lee la oración y selecciona una opción',
      },
      {
        'sentence': 'El gato salta sobre la meza blanca',
        'hasError': true,
        'error': 'meza → mesa',
        'instruction': 'Lee la oración y selecciona una opción',
      },
    ];
    _taskState = speedSentences[(_currentTask - 28) % 4];
  }

  void _handleSpeedAnswer(bool userSaysCorrect) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final hasError = _taskState['hasError'] as bool;
    final isCorrect =
        (userSaysCorrect && !hasError) || (!userSaysCorrect && hasError);

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar
    await _completeTask();
  }

  Widget _buildSpeedTask() {
    final instruction = _taskState['instruction'] as String;
    final sentence = _taskState['sentence'] as String;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  instruction,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Oración para evaluar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            sentence,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        // Botones de respuesta
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _handleSpeedAnswer(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'CORRECTA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            ElevatedButton(
              onPressed: () => _handleSpeedAnswer(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
              ),
              child: Column(
                children: [
                  const Icon(Icons.cancel, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'INCORRECTA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildHelpButton('Detección de errores gramaticales'),
      ],
    );
  }

  // ========== TAREAS DE IDENTIFICAR LETRA INCORRECTA (36-41) ==========
  void _initIdentifyWrongLetterTask() {
    final wordTasks = [
      // Nivel 1-2: Palabras cortas (4-5 letras)
      {
        'word': 'gbato',
        'correct': 'gato',
        'wrongLetter': 'b',
        'wrongIndex': 1,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 1,
      },
      {
        'word': 'cxasa',
        'correct': 'casa',
        'wrongLetter': 'x',
        'wrongIndex': 1,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 1,
      },
      // Nivel 3-4: Palabras medias (5-6 letras)
      {
        'word': 'peqrro',
        'correct': 'perro',
        'wrongLetter': 'q',
        'wrongIndex': 2,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 2,
      },
      {
        'word': 'lipbro',
        'correct': 'libro',
        'wrongLetter': 'p',
        'wrongIndex': 2,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 2,
      },
      // Nivel 5-6: Palabras largas (7-9 letras)
      {
        'word': 'mazbiposa',
        'correct': 'mariposa',
        'wrongLetter': 'z',
        'wrongIndex': 2,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 3,
      },
      {
        'word': 'elefdante',
        'correct': 'elefante',
        'wrongLetter': 'd',
        'wrongIndex': 4,
        'instruction': 'Encuentra la letra que no pertenece',
        'difficulty': 3,
      },
    ];
    final taskIndex = _currentTask - 36;
    _taskState = wordTasks[taskIndex % 6];
  }

  void _handleWrongLetterTap(int index) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final isCorrect = index == _taskState['wrongIndex'];

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar
    await _completeTask();
  }

  Widget _buildIdentifyWrongLetterTask() {
    final instruction = _taskState['instruction'] as String;
    final word = _taskState['word'] as String;
    final letters = word.split('');

    // Ajustar tamaño según longitud de palabra
    final letterWidth = letters.length <= 5
        ? 50.0
        : (letters.length <= 7 ? 44.0 : 38.0);
    final letterHeight = letters.length <= 5
        ? 68.0
        : (letters.length <= 7 ? 60.0 : 54.0);
    final fontSize = letters.length <= 5
        ? 36.0
        : (letters.length <= 7 ? 32.0 : 28.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción compacta
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  instruction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Palabra con letras seleccionables compacta
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 3,
          children: List.generate(letters.length, (index) {
            return Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _handleWrongLetterTap(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: letterWidth,
                  height: letterHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                  child: Text(
                    letters[index],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _buildHelpButton('Identificar letra intrusa en la palabra'),
      ],
    );
  }

  // ========== TAREAS DE COMPLETAR PALABRA (42-47) ==========
  void _initCompleteWordTask() {
    final wordTasks = [
      // Nivel 1-2: Palabras cortas
      {
        'incomplete': 'g_to',
        'correct': 'gato',
        'missingLetter': 'a',
        'missingIndex': 1,
        'options': ['a', 'o', 'e', 'u'],
        'instruction': 'Completa la palabra',
        'difficulty': 1,
      },
      {
        'incomplete': 'c_sa',
        'correct': 'casa',
        'missingLetter': 'a',
        'missingIndex': 1,
        'options': ['a', 'o', 'e', 'u'],
        'instruction': 'Completa la palabra',
        'difficulty': 1,
      },
      // Nivel 3-4: Palabras medias
      {
        'incomplete': 'per_o',
        'correct': 'perro',
        'missingLetter': 'r',
        'missingIndex': 3,
        'options': ['r', 'l', 'd', 't'],
        'instruction': 'Completa la palabra',
        'difficulty': 2,
      },
      {
        'incomplete': 'li_ro',
        'correct': 'libro',
        'missingLetter': 'b',
        'missingIndex': 2,
        'options': ['b', 'd', 'p', 'v'],
        'instruction': 'Completa la palabra',
        'difficulty': 2,
      },
      // Nivel 5-6: Palabras largas
      {
        'incomplete': 'marip_sa',
        'correct': 'mariposa',
        'missingLetter': 'o',
        'missingIndex': 5,
        'options': ['o', 'a', 'u', 'e'],
        'instruction': 'Completa la palabra',
        'difficulty': 3,
      },
      {
        'incomplete': 'elef_nte',
        'correct': 'elefante',
        'missingLetter': 'a',
        'missingIndex': 4,
        'options': ['a', 'e', 'i', 'o'],
        'instruction': 'Completa la palabra',
        'difficulty': 3,
      },
    ];
    final taskIndex = _currentTask - 42;
    _taskState = wordTasks[taskIndex % 6];
  }

  void _handleCompleteWordTap(String letter) async {
    if (_isProcessing) return;

    final clickTime = DateTime.now();
    final reactionTime = clickTime
        .difference(_taskStartTime ?? clickTime)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    _currentClicks++;
    final isCorrect = letter == _taskState['missingLetter'];

    if (isCorrect) {
      _currentHits++;
    } else {
      _currentMisses++;
    }

    // Registrar la selección y avanzar
    await _completeTask();
  }

  Widget _buildCompleteWordTask() {
    final instruction = _taskState['instruction'] as String;
    final incomplete = _taskState['incomplete'] as String;
    final options = _taskState['options'] as List<String>;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instrucción compacta
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, color: Colors.teal.shade700, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  instruction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.teal.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Palabra incompleta compacta
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.shade300, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade100,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            incomplete,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
              letterSpacing: 3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        // Opciones de letras compactas
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((letter) {
            return Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _handleCompleteWordTap(letter),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade300, width: 2),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildHelpButton('Completar palabra con letra faltante'),
      ],
    );
  }

  // ========== COMPLETAR TAREA ==========
  Future<void> _completeTask() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Métricas avanzadas para futuras versiones:
    // final endTime = DateTime.now();
    // final duration = endTime.difference(_taskStartTime ?? endTime).inMilliseconds;
    // final avgReactionTime = _reactionTimes.isNotEmpty
    //     ? _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length
    //     : 0.0;
    // final accuracy = _currentClicks > 0 ? _currentHits / _currentClicks : 0.0;

    // Crear RoundData usando el factory calculate
    final roundData = RoundData.calculate(
      roundNumber: _currentTask + 1,
      clicks: _currentClicks,
      hits: _currentHits,
      misses: _currentMisses,
    );

    _completedRounds.add(roundData);

    // Avanzar o finalizar (48 tareas total)
    if (_currentTask < 47) {
      setState(() {
        _currentTask++;
        _isProcessing = false;
      });
      _animationController.reset();
      _initializeTask();
      _animationController.forward();
    } else {
      await _finishTest();
    }
  }

  String _getTaskType() {
    if (_currentTask < 8) return 'visual';
    if (_currentTask < 16) return 'auditory';
    if (_currentTask < 24) return 'memory';
    if (_currentTask < 32) return 'dictation';
    if (_currentTask < 36) return 'speed';
    if (_currentTask < 42) return 'identify_wrong_letter';
    return 'complete_word';
  }

  Future<void> _finishTest() async {
    final audioService = context.read<AudioService>();
    await audioService.speak(
      '¡Felicidades! Has completado las 48 tareas del test de cribado con dificultad progresiva. '
      'Ahora analizaremos tus patrones de respuesta.',
    );

    if (!mounted) return;

    // Crear ActivityRoundResult para pasar a RoundResultsScreen
    final endTime = DateTime.now();
    final activityResult = ActivityRoundResult(
      activityId: 'screening_test',
      activityName: 'Test de Cribado',
      childId: widget.childId,
      rounds: _completedRounds,
      startTime: _sessionStartTime ?? endTime,
      endTime: endTime,
      totalDuration: endTime.difference(_sessionStartTime ?? endTime),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RoundResultsScreen(
          result: activityResult,
          userId: widget.userId,
          childId: widget.childId,
        ),
      ),
    );
  }

  // ========== WIDGETS DE UTILIDAD ==========
  Widget _buildHelpButton(String helpText) {
    return TextButton.icon(
      onPressed: () async {
        final audioService = context.read<AudioService>();
        await audioService.speak(helpText);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(helpText),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      icon: const Icon(Icons.help_outline),
      label: const Text('Ayuda'),
      style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentTask + 1) / 48;
    final category = _getTaskType();
    final categoryColors = {
      'visual': Colors.blue,
      'auditory': Colors.purple,
      'memory': Colors.orange,
      'dictation': Colors.teal,
      'speed': Colors.red,
      'identify_wrong_letter': Colors.deepOrange,
      'complete_word': Colors.cyan,
    };

    final categoryNames = {
      'visual': 'VISUAL',
      'auditory': 'AUDITIVO',
      'memory': 'MEMORIA',
      'dictation': 'DICTADO',
      'speed': 'VELOCIDAD',
      'identify_wrong_letter': 'IDENTIFICAR',
      'complete_word': 'COMPLETAR',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarea ${_currentTask + 1} de 48',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: categoryColors[category]?.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColors[category]?.shade300 ?? Colors.grey,
                    width: 1,
                  ),
                ),
                child: Text(
                  categoryNames[category] ?? category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryColors[category]?.shade900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                categoryColors[category] ?? Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BUILD PRINCIPAL ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Cribado'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        child: Stack(
          children: [
            Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _buildCurrentTask(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Feedback overlay
            if (_showFeedback)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: _showFeedback ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _feedbackColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _feedbackColor.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        _feedbackMessage,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTask() {
    if (_currentTask < 8) {
      return _buildVisualTask(); // 0-7: Discriminación visual
    } else if (_currentTask < 16) {
      return _buildAuditoryTask(); // 8-15: Correspondencia auditiva
    } else if (_currentTask < 24) {
      return _buildMemoryTask(); // 16-23: Memoria secuencial
    } else if (_currentTask < 32) {
      return _buildDictationTask(); // 24-31: Dictado
    } else if (_currentTask < 36) {
      return _buildSpeedTask(); // 32-35: Velocidad/gramática
    } else if (_currentTask < 42) {
      return _buildIdentifyWrongLetterTask(); // 36-41: Identificar letra incorrecta
    } else {
      return _buildCompleteWordTask(); // 42-47: Completar palabra
    }
  }
}

// Dialog con timer de 5 segundos antes de habilitar el botón
class _WelcomeDialogWithTimer extends StatefulWidget {
  final AudioService audioService;

  const _WelcomeDialogWithTimer({required this.audioService});

  @override
  State<_WelcomeDialogWithTimer> createState() =>
      _WelcomeDialogWithTimerState();
}

class _WelcomeDialogWithTimerState extends State<_WelcomeDialogWithTimer> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _countdown == 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Test de Cribado para Dislexia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Este test evalúa patrones de respuesta en diferentes áreas cognitivas '
                'relacionadas con la dislexia: discriminación visual, memoria secuencial, '
                'procesamiento auditivo, y más. Los resultados son orientativos y no sustituyen '
                'una evaluación profesional.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructionItem(
                        Icons.numbers,
                        '48 tareas',
                        'Actividades variadas',
                      ),
                      const SizedBox(height: 10),
                      _buildInstructionItem(
                        Icons.trending_up,
                        'Dificultad progresiva',
                        'Se vuelven más complejas',
                      ),
                      const SizedBox(height: 10),
                      _buildInstructionItem(
                        Icons.touch_app,
                        'Selecciona una opción',
                        'Toca tu respuesta',
                      ),
                      const SizedBox(height: 10),
                      _buildInstructionItem(
                        Icons.check_circle_outline,
                        'Sin respuestas correctas',
                        'Analizamos patrones',
                      ),
                      const SizedBox(height: 10),
                      _buildInstructionItem(
                        Icons.timer,
                        'Toma tu tiempo',
                        'Sin límite',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? Colors.blue.shade600
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEnabled ? Icons.play_arrow : Icons.hourglass_empty,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEnabled
                          ? '¡Comenzar!'
                          : 'Espera $_countdown segundo${_countdown != 1 ? 's' : ''}...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
