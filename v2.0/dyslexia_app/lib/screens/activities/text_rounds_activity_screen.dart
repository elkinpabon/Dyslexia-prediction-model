import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/round_data.dart';
import '../../services/audio/audio_service.dart';
import '../results/round_results_screen.dart';

/// Actividad 4: Dictado Auditivo (PLOS ONE - Dyspector)
/// Audio de palabra → escribir letra por letra con TextField
/// Validación ortográfica usando similitud de cadenas (PLN básico)
/// 10 rondas con palabras de dificultad progresiva
/// Genera: clicks, hits, misses, score, accuracy, missrate para dataset

class TextRoundsActivityScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const TextRoundsActivityScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<TextRoundsActivityScreen> createState() =>
      _TextRoundsActivityScreenState();
}

class _TextRoundsActivityScreenState extends State<TextRoundsActivityScreen>
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

  // Input de texto
  final TextEditingController _textController = TextEditingController();
  String _userInput = '';
  bool _hasSubmitted = false;

  // Animaciones
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  // Palabras para dictado (dificultad progresiva)
  final List<String> _words = [
    'sol', // 3 letras
    'casa', // 4 letras
    'mesa', // 4 letras
    'libro', // 5 letras
    'perro', // 5 letras
    'escuela', // 7 letras
    'ventana', // 7 letras
    'computadora', // 11 letras
    'bicicleta', // 9 letras
    'mariposa', // 8 letras
  ];

  late String _currentWord;

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
    _textController.dispose();
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
          'Actividad de dictado auditivo. Escucha la palabra y escríbela correctamente. '
          'Completarás 10 rondas. ¿Listo? Comenzamos.',
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
    _userInput = '';
    _hasSubmitted = false;
    _textController.clear();
    _currentWord = _words[_currentRound - 1];

    setState(() {});

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AudioService>().speak(
          'Ronda $_currentRound de $_totalRounds. Escucha la palabra y escríbela',
          rate: 0.45,
          pitch: 1.1,
        );

        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) _playWord();
        });
      }
    });
  }

  void _playWord() {
    context.read<AudioService>().speak(_currentWord, rate: 0.4, pitch: 1.0);
  }

  void _onSubmit() {
    if (_hasSubmitted || _textController.text.trim().isEmpty) return;

    setState(() {
      _userInput = _textController.text.trim().toLowerCase();
      _hasSubmitted = true;
      _clickCount = _userInput.length; // cada letra es un click
    });

    _evaluateRound();
  }

  // PLN: Similitud de Levenshtein para ortografía
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> d = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) d[i][0] = i;
    for (int j = 0; j <= s2.length; j++) d[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return d[s1.length][s2.length];
  }

  void _evaluateRound() {
    final distance = _levenshteinDistance(_userInput, _currentWord);
    final maxLen = _currentWord.length > _userInput.length
        ? _currentWord.length
        : _userInput.length;

    // Calcular hits y misses basados en similitud
    _correctClicks = maxLen - distance;
    _incorrectClicks = distance;

    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: _clickCount,
      hits: _correctClicks,
      misses: _incorrectClicks,
    );

    _completedRounds.add(roundData);

    final accuracy = _currentWord.isEmpty
        ? 0.0
        : _correctClicks / _currentWord.length;
    final isSuccess = accuracy >= 0.7;

    context.read<AudioService>().speak(
      isSuccess
          ? 'Muy bien. Ronda $_currentRound completada.'
          : 'Intenta escribir con más cuidado.',
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
    // Contar como miss si salta
    final roundData = RoundData.calculate(
      roundNumber: _currentRound,
      clicks: 1,
      hits: 0,
      misses: _currentWord.length,
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
      activityId: 'audio_dictation',
      activityName: 'Dictado Auditivo',
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
                    _buildPhraseCard(),
                    _buildRecognizedText(),
                    _buildMicrophoneButton(),
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
        color: Colors.teal.shade50,
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
            icon: const Icon(Icons.arrow_back, color: Colors.teal),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lenguaje',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                Text(
                  'Ronda $_currentRound/$_totalRounds',
                  style: TextStyle(fontSize: 14, color: Colors.teal.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.teal.shade700),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_totalSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
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
      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
      minHeight: 6,
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.headset, size: 48, color: Colors.teal.shade700),
          const SizedBox(height: 12),
          Text(
            'Escucha la palabra y escríbela',
            style: TextStyle(
              fontSize: 18,
              color: Colors.teal.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard() {
    return Column(
      children: [
        // Botón para repetir audio
        ElevatedButton.icon(
          onPressed: _playWord,
          icon: const Icon(Icons.volume_up),
          label: const Text('Repetir palabra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Campo de texto para escribir
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade300, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _textController,
            enabled: !_hasSubmitted,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe aquí...',
              hintStyle: TextStyle(color: Colors.teal.shade300, fontSize: 24),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _onSubmit(),
          ),
        ),
        if (_hasSubmitted) ...[
          const SizedBox(height: 16),
          _buildResultFeedback(),
        ],
      ],
    );
  }

  Widget _buildResultFeedback() {
    final accuracy = _currentWord.isEmpty
        ? 0.0
        : _correctClicks / _currentWord.length;
    final isSuccess = accuracy >= 0.7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green.shade300 : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            size: 48,
            color: isSuccess ? Colors.green.shade600 : Colors.orange.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Palabra correcta: $_currentWord',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu respuesta: $_userInput',
            style: TextStyle(fontSize: 18, color: Colors.teal.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Precisión: ${(accuracy * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedText() {
    return const SizedBox.shrink();
  }

  Widget _buildMicrophoneButton() {
    if (_hasSubmitted) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: _textController.text.trim().isEmpty ? null : _onSubmit,
      icon: const Icon(Icons.send),
      label: const Text('Enviar'),
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
          color: Colors.teal.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, size: 60, color: Colors.teal.shade600),
      ),
    );
  }
}
