import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/audio/openai_stt_service.dart';
import '../services/audio/audio_service.dart';

/// Manejador centralizado de transcripción para actividades
/// Gestiona:
/// - Inicio/parada de grabación sin interrupciones
/// - Obtención de transcripción de OpenAI
/// - Manejo de errores y timeouts
/// - Contexto de actividad para mejorar precisión
class SpeechRecognitionHandler {
  static final SpeechRecognitionHandler _instance =
      SpeechRecognitionHandler._internal();

  factory SpeechRecognitionHandler() => _instance;
  SpeechRecognitionHandler._internal();

  final _logger = Logger();
  final OpenAiSttService _sttService = OpenAiSttService();
  final AudioService _audioService = AudioService();

  bool _isProcessing = false;

  /// Inicializar el manejador
  Future<void> initialize() async {
    await _sttService.initialize();
    _logger.i('✓ Speech Recognition Handler initialized');
  }

  /// Grabar y transcribir voz para una actividad específica
  ///
  /// [activityContext]: Contexto de la actividad para mejorar precisión
  /// [maxDuration]: Tiempo máximo de grabación en segundos
  /// [onProgress]: Callback para mostrar estado de grabación
  /// [onTranscribeStart]: Callback cuando inicia la transcripción
  ///
  /// Retorna: Texto transcrito o null si falla
  Future<String?> recordAndTranscribe({
    String activityContext = 'actividad',
    int maxDuration = 30,
    Function(int)? onProgress, // Duración en segundos
    VoidCallback? onTranscribeStart,
  }) async {
    if (_isProcessing) {
      _logger.w('Already processing audio');
      return null;
    }

    _isProcessing = true;

    try {
      // Detener cualquier TTS en curso
      await _audioService.stopSpeaking();

      // Pequeña pausa para que se estabilice el audio
      await Future.delayed(const Duration(milliseconds: 200));

      // Iniciar grabación
      final recordingStarted = await _sttService.startRecording(
        activityContext: activityContext,
        maxDuration: maxDuration,
      );

      if (!recordingStarted) {
        _logger.e('Failed to start recording');
        return null;
      }

      // Monitor de duración (actualizar cada 100ms)
      final progressTimer = Future.doWhile(() async {
        if (!_sttService.isRecording) return false;

        final duration = _sttService.getCurrentRecordingDuration();
        onProgress?.call(duration);

        // Auto-detener si alcanza duración máxima
        if (duration >= maxDuration) {
          _logger.i('Max duration reached, stopping recording');
          return false;
        }

        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      // Esperar a que termine la grabación
      await progressTimer;

      // Notificar que inicia transcripción
      onTranscribeStart?.call();

      // Detener grabación y obtener transcripción
      final transcribedText = await _sttService.stopRecordingAndTranscribe();

      if (transcribedText == null || transcribedText.isEmpty) {
        _logger.w('No transcription received');
        return null;
      }

      _logger.i('✓ Transcription complete: "$transcribedText"');
      return transcribedText;
    } catch (e) {
      _logger.e('Error in recordAndTranscribe: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Cancelar grabación en curso (ej: cuando usuario navega atrás)
  Future<void> cancelRecording() async {
    await _sttService.cancelRecording();
  }

  /// Obtener duración actual de grabación
  int getCurrentRecordingDuration() {
    return _sttService.getCurrentRecordingDuration();
  }

  /// Limpiar recursos
  void dispose() {
    _sttService.dispose();
    _audioService.dispose();
  }
}

/// Widget para mostrar estado de grabación y transcripción
class RecordingIndicator extends StatefulWidget {
  final bool isRecording;
  final bool isTranscribing;
  final int recordingDuration;

  const RecordingIndicator({
    Key? key,
    required this.isRecording,
    required this.isTranscribing,
    required this.recordingDuration,
  }) : super(key: key);

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTranscribing) {
      // Indicador de transcripción
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Procesando...',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isRecording) {
      // Indicador de grabación activa
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Grabando: ${widget.recordingDuration}s',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sin grabación activa
    return const SizedBox.shrink();
  }
}
