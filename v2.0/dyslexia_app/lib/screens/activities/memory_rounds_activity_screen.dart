import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../models/round_data.dart';
import '../../services/audio/audio_service.dart';
import '../results/round_results_screen.dart';

/// Actividad 3: Memoria Secuencial (PLOS ONE - Dyspector)
/// Memorizar y reproducir secuencias de letras/números
/// Detecta dificultades de memoria de trabajo y orden secuencial
/// 10 rondas con longitud progresiva (3→8 elementos)
/// Genera: clicks, hits, misses, score, accuracy, missrate para dataset

class MemoryRoundsActivityScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const MemoryRoundsActivityScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<MemoryRoundsActivityScreen> createState() =>
      _MemoryRoundsActivityScreenState();
}

class _MemoryRoundsActivityScreenState extends State<MemoryRoundsActivityScreen>
    with TickerProviderStateMixin {
  // Estado de rondas
  int _currentRound = 1;
  static const int _totalRounds = 10;
  List<RoundData> _completedRounds = [];

  // Estado de ronda actual
  int _clickCount = 0;
  int _correctClicks = 0;
  int _incorrectClicks = 0;

  // Cronómetro global
  DateTime? _activityStartTime;
  Timer? _globalTimer;
  int _totalSeconds = 0;

  // Secuencia de letras/números
  late List<String> _targetSequence;
  List<String> _userSequence = [];
  bool _isShowingSequence = false;
  bool _isInputMode = false;
  int _showingIndex = 0;

  // Animaciones
  late AnimationController _scaleController;
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;

  final Random _random = Random();

  // Elementos disponibles: letras mayúsculas y números
  final List<String> _elements = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  // Longitud de secuencia por ronda (progresivo: 3→8)
  final List<int> _sequenceLengths = [3, 3, 4, 4, 5, 5, 6, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _initActivity();
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _scaleController.dispose();
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
          'Actividad de memoria secuencial. Presta mucha atención. '
          'Verás una secuencia de letras y números. Luego, deberás repetirla en el mismo orden. '
          'Completarás 10 rondas. La dificultad aumentará progresivamente. ¿Listo? Comenzamos.',
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
    _userSequence = [];
    _isShowingSequence = false;
    _isInputMode = false;
    _showingIndex = 0;

    final sequenceLength = _sequenceLengths[_currentRound - 1];
    _targetSequence = List.generate(
      sequenceLength,
      (_) => _elements[_random.nextInt(_elements.length)],
    );

    setState(() {});

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda $_currentRound de $_totalRounds. Debes memorizar $sequenceLength elementos. ¡Atención!',
        );
        Future.delayed(const Duration(milliseconds: 1800), _showSequence);
      }
    });
  }

  Future<void> _showSequence() async {
    setState(() => _isShowingSequence = true);

    for (int i = 0; i < _targetSequence.length; i++) {
      if (!mounted) return;
      setState(() => _showingIndex = i);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
    }

    setState(() {
      _isShowingSequence = false;
      _isInputMode = true;
    });

    context.read<AudioService>().speak(
      'Ahora repite la secuencia',
      rate: 0.5,
      pitch: 1.1,
    );
  }

  void _onElementTap(String element) {
    if (!_isInputMode) return;

    setState(() {
      _clickCount++;
      _userSequence.add(element);
    });

    _scaleController.forward().then((_) => _scaleController.reset());

    if (_userSequence.length == _targetSequence.length) {
      _isInputMode = false;
      Future.delayed(const Duration(milliseconds: 500), _evaluateRound);
    }
  }

  void _evaluateRound() {
    // Evaluar precisión de la secuencia
    for (int i = 0; i < _targetSequence.length; i++) {
      if (i < _userSequence.length && _userSequence[i] == _targetSequence[i]) {
        _correctClicks++;
      } else {
        _incorrectClicks++;
      }
    }

    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: _clickCount,
      hits: _correctClicks,
      misses: _incorrectClicks,
    );

    _completedRounds.add(roundData);

    final accuracy = _correctClicks / _targetSequence.length;
    final isSuccess = accuracy >= 0.6;

    context.read<AudioService>().speak(
      isSuccess
          ? 'Excelente memoria. Ronda $_currentRound completada.'
          : 'Intenta memorizar mejor la secuencia.',
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

  Future<void> _finishActivity() async {
    _globalTimer?.cancel();

    final result = ActivityRoundResult(
      activityId: 'sequential_memory',
      activityName: 'Memoria Secuencial',
      rounds: _completedRounds,
      startTime: _activityStartTime!,
      endTime: DateTime.now(),
      totalDuration: Duration(seconds: _totalSeconds),
    );

    await context.read<AudioService>().speak(
      '¡Actividad completada! Memoria: ${(result.averageAccuracy * 100).toStringAsFixed(1)} por ciento',
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
                    if (_isShowingSequence) _buildSequenceDisplay(),
                    if (_isInputMode) _buildUserSequence(),
                    _buildColorGrid(),
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
        color: Colors.pink.shade50,
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
            icon: const Icon(Icons.arrow_back, color: Colors.pink),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memoria',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade900,
                  ),
                ),
                Text(
                  'Ronda $_currentRound/$_totalRounds - ${_targetSequence.length} colores',
                  style: TextStyle(fontSize: 14, color: Colors.pink.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.pink.shade700),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_totalSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade900,
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
      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
      minHeight: 6,
    );
  }

  Widget _buildInstructions() {
    String instruction = '';
    if (_isShowingSequence) {
      instruction = 'Memoriza la secuencia...';
    } else if (_isInputMode) {
      instruction = '¡Repite la secuencia!';
    } else {
      instruction = 'Preparado...';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.pink.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            _isShowingSequence
                ? Icons.visibility
                : _isInputMode
                ? Icons.touch_app
                : Icons.psychology,
            size: 48,
            color: Colors.pink.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            instruction,
            style: TextStyle(
              fontSize: 22,
              color: Colors.pink.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceDisplay() {
    final currentElement = _targetSequence[_showingIndex];

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.pink.shade600],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          currentElement,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserSequence() {
    return Wrap(
      spacing: 8,
      children: List.generate(_targetSequence.length, (i) {
        if (i >= _userSequence.length) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(fontSize: 24, color: Colors.grey.shade500),
              ),
            ),
          );
        }

        final element = _userSequence[i];
        final isCorrect = element == _targetSequence[i];

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              element,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildColorGrid() {
    if (!_isInputMode) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _elements.map((element) {
        return GestureDetector(
          onTap: () => _onElementTap(element),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.pink.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  element,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _successAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.pink.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, size: 60, color: Colors.pink.shade600),
      ),
    );
  }
}
