import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../models/round_data.dart';
import '../../services/audio/audio_service.dart';
import '../results/round_results_screen.dart';

/// Actividad 1: Discriminación Visual de Letras Confundibles
/// Basada en Dyspector y PLOS ONE - Detecta confusión b/d/p/q
/// El niño busca todas las letras iguales a la letra objetivo
/// Métricas: Clicks, Hits, Misses, Score, Accuracy, Missrate

class VisualDiscriminationActivityScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const VisualDiscriminationActivityScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<VisualDiscriminationActivityScreen> createState() =>
      _VisualDiscriminationActivityScreenState();
}

class _VisualDiscriminationActivityScreenState
    extends State<VisualDiscriminationActivityScreen>
    with TickerProviderStateMixin {
  // Estado de rondas
  int _currentRound = 1;
  static const int _totalRounds = 10;
  List<RoundData> _completedRounds = [];

  // Estado de ronda actual
  int _clicks = 0;
  int _hits = 0;
  int _misses = 0;

  // Cronómetro global
  DateTime? _activityStartTime;
  Timer? _globalTimer;
  int _totalSeconds = 0;

  // Letras confundibles (característica clave de dislexia)
  static const List<List<String>> _confusableGroups = [
    ['b', 'd', 'p', 'q'], // Grupo 1: Rotaciones
    ['m', 'n', 'u'], // Grupo 2: Similar forma
    ['a', 'e', 'o'], // Grupo 3: Vocales redondas
    ['f', 't', 'l'], // Grupo 4: Verticales
    ['s', 'z', '5'], // Grupo 5: Curvas similares
  ];

  String _targetLetter = '';
  List<_LetterTile> _letterGrid = [];
  Set<int> _selectedIndices = {};
  Set<int> _correctIndices = {};

  final Random _random = Random();
  late AnimationController _successAnimController;
  late AnimationController _errorAnimController;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _errorAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initActivity();
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _successAnimController.dispose();
    _errorAnimController.dispose();
    super.dispose();
  }

  void _initActivity() {
    _activityStartTime = DateTime.now();
    _startGlobalTimer();
    _startRound();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Actividad de discriminación visual. Busca todas las letras iguales a la letra objetivo. '
          'Ten mucho cuidado, porque hay letras muy parecidas. Completarás 10 rondas. ¡Adelante!',
        );
      }
    });
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _totalSeconds++);
      }
    });
  }

  void _startRound() {
    setState(() {
      _clicks = 0;
      _hits = 0;
      _misses = 0;
      _selectedIndices.clear();
      _correctIndices.clear();
      _generateLetterGrid();
    });

    // Instrucción por voz
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda $_currentRound de $_totalRounds. Busca todas las letras $_targetLetter. '
          'Toca cada una que encuentres.',
        );
      }
    });
  }

  void _generateLetterGrid() {
    // Seleccionar grupo de letras confundibles
    final groupIndex = _currentRound % _confusableGroups.length;
    final confusableGroup = _confusableGroups[groupIndex];

    // Letra objetivo (la que debe buscar)
    _targetLetter = confusableGroup[_random.nextInt(confusableGroup.length)];

    // Tamaño de grid progresivo: 3x3(9), 4x4(16), 5x5(25), 6x6(36)
    int gridSize;
    if (_currentRound <= 3) {
      gridSize = 3; // 9 letras
    } else if (_currentRound <= 6) {
      gridSize = 4; // 16 letras
    } else if (_currentRound <= 8) {
      gridSize = 5; // 25 letras
    } else {
      gridSize = 6; // 36 letras
    }

    final totalTiles = gridSize * gridSize;

    // Determinar cuántas letras objetivo incluir (20-40% del grid)
    final targetCount = (totalTiles * (0.2 + _random.nextDouble() * 0.2))
        .round();

    _letterGrid = [];
    _correctIndices.clear();

    // Crear lista de letras
    final List<String> letters = [];
    for (int i = 0; i < targetCount; i++) {
      letters.add(_targetLetter);
      _correctIndices.add(i);
    }

    // Rellenar con distractores del mismo grupo
    while (letters.length < totalTiles) {
      final distractor =
          confusableGroup[_random.nextInt(confusableGroup.length)];
      if (distractor != _targetLetter || _random.nextDouble() < 0.1) {
        letters.add(distractor);
      }
    }

    // Mezclar letras
    letters.shuffle(_random);

    // Actualizar índices correctos después de mezclar
    _correctIndices.clear();
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] == _targetLetter) {
        _correctIndices.add(i);
      }
    }

    // Crear tiles
    for (int i = 0; i < letters.length; i++) {
      _letterGrid.add(_LetterTile(letter: letters[i], index: i));
    }
  }

  void _onLetterTap(int index) {
    if (_selectedIndices.contains(index)) {
      // Ya seleccionada, no hacer nada
      return;
    }

    setState(() {
      _clicks++;
      _selectedIndices.add(index);

      if (_correctIndices.contains(index)) {
        // Correcto
        _hits++;
        _successAnimController.forward(from: 0);
        context.read<AudioService>().speak('Bien', rate: 0.5, pitch: 1.2);
      } else {
        // Error
        _misses++;
        _errorAnimController.forward(from: 0);
        context.read<AudioService>().speak('Esa no', rate: 0.5, pitch: 0.9);
      }
    });

    // Verificar si completó la ronda
    if (_selectedIndices.containsAll(_correctIndices) ||
        _selectedIndices.length >= _letterGrid.length * 0.8) {
      _completeRound();
    }
  }

  void _completeRound() {
    // Calcular métricas finales
    final actualMisses = _correctIndices.length - _hits;
    final finalMisses = _misses + actualMisses;

    final roundData = RoundData(
      roundNumber: _currentRound,
      clicks: _clicks,
      hits: _hits,
      misses: finalMisses,
      score: _hits,
      accuracy: _clicks > 0 ? _hits / _clicks : 0.0,
      missrate: _clicks > 0 ? finalMisses / _clicks : 0.0,
      timestamp: DateTime.now(),
    );

    _completedRounds.add(roundData);

    // Feedback de voz
    final accuracy = (roundData.accuracy * 100).toInt();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda completada. Precisión: $accuracy por ciento',
          rate: 0.45,
          pitch: 1.1,
        );
      }
    });

    if (_currentRound < _totalRounds) {
      // Siguiente ronda
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentRound++;
            _startRound();
          });
        }
      });
    } else {
      // Actividad completa
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _finishActivity();
        }
      });
    }
  }

  void _finishActivity() {
    final endTime = DateTime.now();
    final duration = endTime.difference(_activityStartTime!);

    final result = ActivityRoundResult(
      activityId: 'visual_discrimination',
      activityName: 'Discriminación Visual',
      rounds: _completedRounds,
      startTime: _activityStartTime!,
      endTime: endTime,
      totalDuration: duration,
    );

    context.read<AudioService>().speak(
      '¡Actividad completada! Has completado las $_totalRounds rondas.',
      rate: 0.45,
      pitch: 1.2,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoundResultsScreen(
          result: result,
          userId: widget.userId,
          childId: widget.childId,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = _letterGrid.isEmpty ? 3 : sqrt(_letterGrid.length).round();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              const SizedBox(height: 16),
              _buildTargetLetterCard(),
              const SizedBox(height: 24),
              Expanded(child: _buildLetterGrid(gridSize)),
              _buildMetricsRow(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.indigo.shade200, width: 2),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discriminación Visual',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
                Text(
                  'Ronda $_currentRound/$_totalRounds',
                  style: TextStyle(color: Colors.indigo.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.shade300),
            ),
            child: Text(
              _formatTime(_totalSeconds),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(
        value: _currentRound / _totalRounds,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        minHeight: 6,
      ),
    );
  }

  Widget _buildTargetLetterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade100, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Busca todas las letras:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.indigo, width: 3),
            ),
            child: Center(
              child: Text(
                _targetLetter.toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterGrid(int gridSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _letterGrid.length,
        itemBuilder: (context, index) {
          final tile = _letterGrid[index];
          final isSelected = _selectedIndices.contains(index);
          final isCorrect = _correctIndices.contains(index);

          return GestureDetector(
            onTap: () => _onLetterTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isCorrect ? Colors.green : Colors.red)
                      : Colors.indigo.shade200,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isCorrect ? Colors.green : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  tile.letter.toUpperCase(),
                  style: TextStyle(
                    fontSize: gridSize <= 4 ? 32 : (gridSize == 5 ? 24 : 20),
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isCorrect
                              ? Colors.green.shade900
                              : Colors.red.shade900)
                        : Colors.indigo.shade900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('Clicks', _clicks, Colors.blue),
          _buildMetricItem('Aciertos', _hits, Colors.green),
          _buildMetricItem('Errores', _misses, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _LetterTile {
  final String letter;
  final int index;

  _LetterTile({required this.letter, required this.index});
}
