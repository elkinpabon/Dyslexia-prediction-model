import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/round_data.dart';
import '../../services/audio/audio_service.dart';
import '../results/round_results_screen.dart';

/// Actividad 5: Detección de Errores Ortográficos (PLOS ONE - Dyspector)
/// Mostrar frases con 1-2 palabras mal escritas
/// Usuario toca palabras incorrectas → validación PLN
/// Métricas: Clicks (toques), Hits (correctos), Misses (falsos positivos)

class SpeedRoundsActivityScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const SpeedRoundsActivityScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<SpeedRoundsActivityScreen> createState() =>
      _SpeedRoundsActivityScreenState();
}

class _SpeedRoundsActivityScreenState extends State<SpeedRoundsActivityScreen>
    with TickerProviderStateMixin {
  // Estado de rondas
  int _currentRound = 1;
  static const int _totalRounds = 10;
  List<RoundData> _completedRounds = [];

  // Estado de ronda actual
  int _clickCount = 0;
  int _correctClicks = 0;
  int _incorrectClicks = 0;
  Set<int> _tappedIndices = {};
  bool _hasSubmitted = false;

  // Cronómetro global
  DateTime? _activityStartTime;
  Timer? _globalTimer;
  int _totalSeconds = 0;

  // Animaciones
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  // Frases con errores ortográficos para cada ronda
  // Format: {words: [...], errorIndices: [index of misspelled words]}
  final List<Map<String, dynamic>> _sentences = [
    {
      'words': ['El', 'sol', 'briya', 'en', 'el', 'cielo', 'azul'],
      'errorIndices': [2], // briya → brilla
    },
    {
      'words': ['Los', 'pajaros', 'cantan', 'en', 'el', 'arbol'],
      'errorIndices': [1, 5], // pajaros → pájaros, arbol → árbol
    },
    {
      'words': ['Me', 'gusta', 'jugar', 'con', 'mi', 'perro', 'fiel'],
      'errorIndices': [], // Sin errores (control)
    },
    {
      'words': ['La', 'escuela', 'es', 'muy', 'grande', 'y', 'ermosa'],
      'errorIndices': [6], // ermosa → hermosa
    },
    {
      'words': ['Voy', 'a', 'comer', 'frutas', 'y', 'verduras', 'frescas'],
      'errorIndices': [], // Sin errores (control)
    },
    {
      'words': ['El', 'niño', 'corre', 'rapido', 'por', 'el', 'parque'],
      'errorIndices': [3], // rapido → rápido
    },
    {
      'words': ['Las', 'flores', 'del', 'jardin', 'son', 'muy', 'bonitas'],
      'errorIndices': [3], // jardin → jardín
    },
    {
      'words': ['Mi', 'mamá', 'cosina', 'delicioso', 'todos', 'los', 'dias'],
      'errorIndices': [2, 6], // cosina → cocina, dias → días
    },
    {
      'words': ['Leo', 'libros', 'interesantes', 'en', 'la', 'biblioteca'],
      'errorIndices': [], // Sin errores (control)
    },
    {
      'words': ['El', 'agua', 'del', 'rio', 'esta', 'muy', 'fria', 'hoy'],
      'errorIndices': [3, 4, 6], // rio → río, esta → está, fria → fría
    },
  ];

  late Map<String, dynamic> _currentSentence;
  late List<String> _currentWords;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _initActivity();
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  void _initActivity() {
    _activityStartTime = DateTime.now();
    _startGlobalTimer();
    _startRound();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Actividad de detección de errores ortográficos. Lee cuidadosamente cada frase. '
          'Algunas palabras están mal escritas. Debes tocar todas las palabras incorrectas que encuentres. '
          'Completarás 10 rondas. ¿Estás listo? Comenzamos.',
        );
      }
    });
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _totalSeconds++);
    });
  }

  void _startRound() {
    _clickCount = 0;
    _correctClicks = 0;
    _incorrectClicks = 0;
    _tappedIndices.clear();
    _hasSubmitted = false;

    _currentSentence = _sentences[_currentRound - 1];
    _currentWords = List<String>.from(_currentSentence['words']);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda $_currentRound de $_totalRounds. Lee con cuidado la frase, y toca todas las palabras que estén mal escritas.',
        );
      }
    });
  }

  void _onWordTap(int index) {
    if (_hasSubmitted) return;

    setState(() {
      if (_tappedIndices.contains(index)) {
        _tappedIndices.remove(index);
      } else {
        _tappedIndices.add(index);
      }
      _clickCount = _tappedIndices.length;
    });
  }

  void _onSubmit() {
    if (_hasSubmitted) return;

    setState(() => _hasSubmitted = true);
    _evaluateRound();
  }

  void _evaluateRound() {
    final errorIndices = Set<int>.from(_currentSentence['errorIndices']);

    // Calcular hits: palabras incorrectas correctamente identificadas
    _correctClicks = _tappedIndices.intersection(errorIndices).length;

    // Calcular misses: falsos positivos (marcó correctas como incorrectas)
    _incorrectClicks = _tappedIndices.difference(errorIndices).length;

    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: _clickCount,
      hits: _correctClicks,
      misses: _incorrectClicks,
    );

    _completedRounds.add(roundData);

    final totalErrors = errorIndices.length;
    final accuracy = totalErrors == 0 ? 1.0 : _correctClicks / totalErrors;
    final isSuccess = accuracy >= 0.7;

    context.read<AudioService>().speak(
      isSuccess
          ? 'Excelente. Ronda $_currentRound completada.'
          : 'Intenta revisar con más atención.',
      rate: 0.5,
      pitch: isSuccess ? 1.3 : 0.9,
    );

    if (_currentRound < _totalRounds) {
      _successController.forward().then((_) {
        _successController.reset();
        setState(() {
          _currentRound++;
          _startRound();
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), _finishActivity);
    }
  }

  void _skipRound() {
    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: 0,
      hits: 0,
      misses: _currentSentence['errorIndices'].length,
    );

    _completedRounds.add(roundData);

    if (_currentRound < _totalRounds) {
      setState(() {
        _currentRound++;
        _startRound();
      });
    } else {
      _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
    _globalTimer?.cancel();

    final result = ActivityRoundResult(
      activityId: 'spelling_error_detection',
      activityName: 'Detección de Errores Ortográficos',
      rounds: _completedRounds,
      startTime: _activityStartTime!,
      endTime: DateTime.now(),
      totalDuration: Duration(seconds: _totalSeconds),
    );

    await context.read<AudioService>().speak(
      '¡Actividad completada! Precisión: ${(result.averageAccuracy * 100).toStringAsFixed(1)} por ciento',
      rate: 0.45,
      pitch: 1.1,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoundResultsScreen(
            result: result,
            userId: widget.userId,
            childId: widget.childId,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInstructions(),
                    _buildSentenceDisplay(),
                    if (!_hasSubmitted) _buildSubmitButton(),
                    if (_hasSubmitted) _buildResultFeedback(),
                    _buildSkipButton(),
                    _buildSuccessAnimation(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Errores Ortográficos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
                Text(
                  'Ronda $_currentRound/$_totalRounds',
                  style: TextStyle(fontSize: 14, color: Colors.purple.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.purple.shade700),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_totalSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _currentRound / _totalRounds,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
      minHeight: 6,
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.spellcheck, size: 48, color: Colors.purple.shade700),
          const SizedBox(height: 12),
          Text(
            'Toca las palabras que estén mal escritas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.purple.shade800,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade300, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(_currentWords.length, (index) {
          final word = _currentWords[index];
          final isTapped = _tappedIndices.contains(index);
          final isError = (_currentSentence['errorIndices'] as List).contains(
            index,
          );

          Color backgroundColor;
          Color borderColor;

          if (_hasSubmitted) {
            if (isError && isTapped) {
              // Correcto: error identificado
              backgroundColor = Colors.green.shade100;
              borderColor = Colors.green.shade600;
            } else if (isError && !isTapped) {
              // Miss: error no identificado
              backgroundColor = Colors.red.shade100;
              borderColor = Colors.red.shade600;
            } else if (!isError && isTapped) {
              // Falso positivo
              backgroundColor = Colors.orange.shade100;
              borderColor = Colors.orange.shade600;
            } else {
              // Correcto: palabra correcta no marcada
              backgroundColor = Colors.white;
              borderColor = Colors.grey.shade300;
            }
          } else {
            backgroundColor = isTapped ? Colors.purple.shade100 : Colors.white;
            borderColor = isTapped
                ? Colors.purple.shade600
                : Colors.grey.shade300;
          }

          return GestureDetector(
            onTap: () => _onWordTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade900,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _tappedIndices.isEmpty ? null : _onSubmit,
      icon: const Icon(Icons.check_circle),
      label: const Text('Enviar Respuesta'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResultFeedback() {
    final errorIndices = Set<int>.from(_currentSentence['errorIndices']);
    final totalErrors = errorIndices.length;
    final accuracy = totalErrors == 0
        ? 100.0
        : (_correctClicks / totalErrors * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accuracy >= 70 ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accuracy >= 70
              ? Colors.green.shade300
              : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            accuracy >= 70 ? Icons.check_circle : Icons.info,
            size: 48,
            color: accuracy >= 70
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Errores encontrados: $_correctClicks de $totalErrors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Falsos positivos: $_incorrectClicks',
            style: TextStyle(fontSize: 16, color: Colors.purple.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Precisión: ${accuracy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: accuracy >= 70
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return ElevatedButton.icon(
      onPressed: _skipRound,
      icon: const Icon(Icons.skip_next),
      label: const Text('Saltar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _successAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.purple.shade600,
        ),
      ),
    );
  }
}
