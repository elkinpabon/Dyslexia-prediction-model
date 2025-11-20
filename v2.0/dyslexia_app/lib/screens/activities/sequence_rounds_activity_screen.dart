import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/round_data.dart';
import '../../services/audio/audio_service.dart';
import '../results/round_results_screen.dart';

/// Actividad 2: Correspondencia Sonido-Letra (PLOS ONE - Dyspector)
/// Audio de fonema → seleccionar letra correcta entre confundibles
/// Detecta confusión de letras visualmente similares (b/d/p/q, m/n, f/v)
/// 10 rondas con dificultad progresiva
/// Genera: clicks, hits, misses, score, accuracy, missrate para dataset

class SequenceRoundsActivityScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const SequenceRoundsActivityScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<SequenceRoundsActivityScreen> createState() =>
      _SequenceRoundsActivityScreenState();
}

class _SequenceRoundsActivityScreenState
    extends State<SequenceRoundsActivityScreen>
    with TickerProviderStateMixin {
  // Estado de rondas
  int _currentRound = 1;
  static const int _totalRounds = 10;
  List<RoundData> _completedRounds = [];

  // Estado de ronda actual
  int _clickCount = 0; // Total de clicks (intentos)
  int _correctClicks = 0; // Aciertos
  int _incorrectClicks = 0; // Errores

  // Cronómetro global
  DateTime? _activityStartTime;
  Timer? _globalTimer;
  int _totalSeconds = 0;

  // Pares de letra target y opciones confundibles por ronda
  final List<Map<String, dynamic>> _roundConfigs = [
    {
      'target': 'b',
      'options': ['b', 'd', 'p', 'q'],
      'audio': 'be',
    }, // Ronda 1
    {
      'target': 'd',
      'options': ['d', 'b', 'p', 'q'],
      'audio': 'de',
    }, // Ronda 2
    {
      'target': 'p',
      'options': ['p', 'b', 'd', 'q'],
      'audio': 'pe',
    }, // Ronda 3
    {
      'target': 'q',
      'options': ['q', 'b', 'd', 'p'],
      'audio': 'ku',
    }, // Ronda 4
    {
      'target': 'm',
      'options': ['m', 'n', 'u', 'w'],
      'audio': 'eme',
    }, // Ronda 5
    {
      'target': 'n',
      'options': ['n', 'm', 'u', 'h'],
      'audio': 'ene',
    }, // Ronda 6
    {
      'target': 'f',
      'options': ['f', 'v', 't', 'l'],
      'audio': 'efe',
    }, // Ronda 7
    {
      'target': 'v',
      'options': ['v', 'f', 'u', 'y'],
      'audio': 've',
    }, // Ronda 8
    {
      'target': 's',
      'options': ['s', 'z', 'c', '5'],
      'audio': 'ese',
    }, // Ronda 9
    {
      'target': 'z',
      'options': ['z', 's', '2', '5'],
      'audio': 'zeta',
    }, // Ronda 10
  ];

  String _targetLetter = '';
  List<String> _optionLetters = [];
  String? _selectedLetter;
  bool _showFeedback = false;

  // Animaciones
  late AnimationController _scaleController;
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;

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
          'Actividad de correspondencia sonido-letra. Escucha con atención. '
          'Oirás un sonido, y deberás seleccionar la letra correcta entre varias opciones muy parecidas. '
          'Completarás 10 rondas. ¡Presta mucha atención! Comenzamos.',
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

    final config = _roundConfigs[_currentRound - 1];
    _targetLetter = config['target'];
    _optionLetters = List<String>.from(config['options'])..shuffle();
    _selectedLetter = null;
    _showFeedback = false;

    setState(() {});

    // Reproducir audio del fonema
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda $_currentRound de $_totalRounds. Escucha el sonido, y selecciona la letra correcta.',
        );

        Future.delayed(const Duration(milliseconds: 2800), () {
          if (mounted) {
            _playPhonemeSound(config['audio']);
          }
        });
      }
    });
  }

  void _playPhonemeSound(String phoneme) {
    context.read<AudioService>().speak(phoneme, rate: 0.3, pitch: 1.0);
  }

  void _onLetterTap(String letter) {
    if (_selectedLetter != null) return; // Ya seleccionó

    setState(() {
      _clickCount++;
      _selectedLetter = letter;
      _showFeedback = true;

      if (letter == _targetLetter) {
        _correctClicks++;
      } else {
        _incorrectClicks++;
      }
    });

    _scaleController.forward().then((_) => _scaleController.reset());

    _evaluateRound();
  }

  void _onRepeatAudio() {
    final config = _roundConfigs[_currentRound - 1];
    _playPhonemeSound(config['audio']);
  }

  void _evaluateRound() {
    final isCorrect = _selectedLetter == _targetLetter;

    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: _clickCount,
      hits: _correctClicks,
      misses: _incorrectClicks,
    );

    _completedRounds.add(roundData);

    if (isCorrect) {
      _successController.forward().then((_) {
        _successController.reset();
      });

      context.read<AudioService>().speak(
        '¡Correcto! Es la letra $_targetLetter',
        rate: 0.5,
        pitch: 1.2,
      );
    } else {
      context.read<AudioService>().speak(
        'Incorrecto. Era la letra $_targetLetter',
        rate: 0.5,
        pitch: 0.8,
      );
    }

    // Avanzar a siguiente ronda
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (_currentRound < _totalRounds) {
        setState(() {
          _currentRound++;
          _startRound();
        });
      } else {
        _finishActivity();
      }
    });
  }

  Future<void> _finishActivity() async {
    _globalTimer?.cancel();

    final result = ActivityRoundResult(
      activityId: 'sound_letter_correspondence',
      activityName: 'Correspondencia Sonido-Letra',
      rounds: _completedRounds,
      startTime: _activityStartTime!,
      endTime: DateTime.now(),
      totalDuration: Duration(seconds: _totalSeconds),
    );

    await context.read<AudioService>().speak(
      '¡Actividad completada! Precisión promedio: ${(result.averageAccuracy * 100).toStringAsFixed(1)} por ciento',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildWordDisplay(),
                    const SizedBox(height: 32),
                    _buildUserSequence(),
                    const SizedBox(height: 48),
                    _buildShuffledLetters(),
                    const SizedBox(height: 24),
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
        color: Colors.blue.shade50,
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
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correspondencia Sonido-Letra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'Ronda $_currentRound/$_totalRounds',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_totalSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
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
      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
      minHeight: 6,
    );
  }

  Widget _buildWordDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.hearing, size: 56, color: Colors.blue.shade700),
          const SizedBox(height: 16),
          Text(
            'Escucha el sonido',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _onRepeatAudio,
            icon: const Icon(Icons.volume_up, size: 28),
            label: const Text('Repetir sonido', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¿Qué letra corresponde al sonido?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserSequence() {
    if (_selectedLetter == null) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Text(
            'Selecciona una letra...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final isCorrect = _selectedLetter == _targetLetter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            size: 40,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect ? '¡Correcto!' : 'Incorrecto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                ),
              ),
              Text(
                'Seleccionaste: $_selectedLetter',
                style: TextStyle(
                  fontSize: 16,
                  color: isCorrect
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              if (!isCorrect)
                Text(
                  'Correcta: $_targetLetter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShuffledLetters() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: _optionLetters.map((letter) {
        final isSelected = _selectedLetter == letter;
        final isTarget = letter == _targetLetter;
        final showCorrect = _showFeedback && isTarget;

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () => _onLetterTap(letter),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: showCorrect
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : isSelected
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 42,
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
          color: Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, size: 60, color: Colors.green.shade600),
      ),
    );
  }
}
