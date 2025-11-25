import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Servicio de transcripción usando OpenAI Whisper API (Speech-to-Text)
/// - Mejor precisión y comprensión del español
/// - Manejo inteligente del audio sin interrupciones
/// - Gestión eficiente de contexto de actividad
class OpenAiSttService {
  static final OpenAiSttService _instance = OpenAiSttService._internal();
  factory OpenAiSttService() => _instance;
  OpenAiSttService._internal();

  final _logger = Logger();
  final _audioRecorder = AudioRecorder();

  // Configuración de OpenAI
  // IMPORTANTE: Cargar desde variables de entorno, NO hardcodear
  static const String _openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String _openAiEndpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  bool _shouldStopRecording = false;

  // Control de contexto para no repetir palabras clave
  String _lastActivityContext = '';
  List<String> _previousTranscriptions = [];

  bool get isRecording => _isRecording;

  /// Inicializar el servicio de grabación de audio
  Future<void> initialize() async {
    try {
      // Verificar permisos de micrófono
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _logger.w('Audio recording permission denied');
        return;
      }
      _logger.i('✓ OpenAI STT service initialized');
    } catch (e) {
      _logger.e('Error initializing STT service: $e');
    }
  }

  /// Iniciar grabación de audio para actividad específica
  /// [activityContext]: Contexto de la actividad (ej: "dictado", "memoria", "velocidad")
  /// [maxDuration]: Duración máxima en segundos
  Future<bool> startRecording({
    String activityContext = 'actividad',
    int maxDuration = 30,
  }) async {
    if (_isRecording) {
      _logger.w('Already recording');
      return false;
    }

    try {
      _lastActivityContext = activityContext;
      _shouldStopRecording = false;
      _recordingStartTime = DateTime.now();

      // Obtener ruta temporal para guardar audio
      final dir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${dir.path}/stt_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Iniciar grabación con configuración óptima
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000, // 128 kbps para buena calidad
          sampleRate: 16000, // 16 kHz ideal para Whisper
          numChannels: 1, // Mono es suficiente
          autoGain: true, // Ajuste automático de ganancia
          echoCancel: true, // Cancelación de eco
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _logger.i(
        '🎤 Recording started for: $activityContext (max ${maxDuration}s)',
      );

      // Auto-stop después de duración máxima
      _scheduleAutoStop(maxDuration);

      return true;
    } catch (e) {
      _logger.e('Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Agendar detención automática de grabación
  void _scheduleAutoStop(int maxDuration) {
    Future.delayed(Duration(seconds: maxDuration), () {
      if (_isRecording && !_shouldStopRecording) {
        _logger.i('Auto-stopping recording after $maxDuration seconds');
        _shouldStopRecording = true;
      }
    });
  }

  /// Detener grabación y obtener transcripción de OpenAI
  /// Retorna el texto transcrito (sin anuncios de finalización)
  Future<String?> stopRecordingAndTranscribe() async {
    if (!_isRecording) {
      _logger.w('Not recording');
      return null;
    }

    try {
      _isRecording = false;

      // Detener grabación
      final recordingPath = await _audioRecorder.stop();
      _logger.i('🛑 Recording stopped: $recordingPath');

      if (recordingPath == null || recordingPath.isEmpty) {
        _logger.e('No recording path returned');
        return null;
      }

      // Verificar que el archivo existe y tiene contenido
      final file = File(recordingPath);
      if (!await file.exists()) {
        _logger.e('Recording file does not exist: $recordingPath');
        return null;
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        // Menos de 1KB probablemente es ruido/silencio
        _logger.w('Recording too short or empty: ${fileSize}B');
        return null;
      }

      _logger.i(
        '📤 Sending audio to OpenAI Whisper API (${(fileSize / 1024).toStringAsFixed(1)}KB)...',
      );

      // Enviar a OpenAI Whisper
      final transcription = await _transcribeWithOpenAi(recordingPath);

      // Limpiar archivo temporal
      await file
          .delete()
          .then((_) {
            _logger.i('Temp audio file deleted');
          })
          .catchError((e) {
            _logger.w('Could not delete temp file: $e');
          });

      return transcription;
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Transcribir audio usando OpenAI Whisper API
  /// Retorna solo el texto transcrito, sin mensajes adicionales
  Future<String?> _transcribeWithOpenAi(String audioPath) async {
    try {
      // Crear request multipart para la API de OpenAI
      final request = http.MultipartRequest('POST', Uri.parse(_openAiEndpoint));

      // Agregar headers
      request.headers['Authorization'] = 'Bearer $_openAiApiKey';

      // Agregar archivo de audio
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath,
          filename: 'audio.wav',
        ),
      );

      // Agregar parámetros
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'es'; // Español explícito
      request.fields['response_format'] = 'json';

      // Opcional: Agregar prompt para mejorar precisión
      // en contextos específicos
      if (_lastActivityContext.isNotEmpty) {
        String prompt = _generateContextPrompt(_lastActivityContext);
        request.fields['prompt'] = prompt;
      }

      // Enviar request
      _logger.i('🚀 Sending to OpenAI Whisper API...');
      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Whisper API timeout after 60 seconds');
        },
      );

      if (response.statusCode != 200) {
        _logger.e('OpenAI API error: ${response.statusCode}');
        final body = await response.stream.bytesToString();
        _logger.e('Response: $body');
        return null;
      }

      // Parsear respuesta
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      final transcribedText = (jsonResponse['text'] as String?)?.trim() ?? '';

      if (transcribedText.isEmpty) {
        _logger.w('Empty transcription received');
        return null;
      }

      _logger.i('✓ Transcribed: "$transcribedText"');

      // Procesar el texto para mejorar precisión
      final processedText = _postProcessTranscription(transcribedText);

      // Guardar en histórico para contexto futuro
      _previousTranscriptions.add(processedText);
      if (_previousTranscriptions.length > 10) {
        _previousTranscriptions.removeAt(0);
      }

      return processedText;
    } on Exception catch (e) {
      _logger.e('Exception: $e');
      return null;
    } catch (e) {
      _logger.e('Error transcribing with OpenAI: $e');
      return null;
    }
  }

  /// Generar prompt contextual para mejorar precisión de Whisper
  String _generateContextPrompt(String activityContext) {
    // Vocabulario específico según el tipo de actividad
    final vocabularyMap = {
      'dictado': 'Palabras españolas comunes, enfocarse en pronunciación clara',
      'memoria': 'Secuencias de letras, números de una en una, sin palabras',
      'velocidad': 'Texto literario corto con palabras comunes en español',
      'audición': 'Letras individuales pronunciadas claramente',
      'ortografía': 'Palabras españolas con enfoque en ortografía',
      'discriminación': 'Pares de palabras similares que suenan parecido',
    };

    return vocabularyMap[activityContext] ??
        'Transcribir texto hablado en español de manera precisa y clara';
  }

  /// Post-procesar transcripción para mejorar precisión
  /// - Normalizar puntuación
  /// - Eliminar artefactos
  /// - Mantener contexto de actividad
  String _postProcessTranscription(String text) {
    var processed = text.trim();

    // 1. Normalizar espacios múltiples
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    // 2. Remover puntuación innecesaria al final (excepto en dictado)
    if (_lastActivityContext != 'dictado') {
      processed = processed.replaceAll(RegExp(r'[.,!?]+$'), '');
    }

    // 3. Normalizar mayúsculas según contexto
    if (_lastActivityContext == 'memoria' ||
        _lastActivityContext == 'audición') {
      // Para secuencias de letras, mantener mayúsculas
      processed = processed.toUpperCase();
    } else if (_lastActivityContext == 'dictado') {
      // Para dictado, primera letra mayúscula
      if (processed.isNotEmpty) {
        processed = processed[0].toUpperCase() + processed.substring(1);
      }
    }

    // 4. Eliminar palabras de relleno comunes
    final fillerWords = ['este', 'uh', 'um', 'ya', 'bueno'];
    for (final filler in fillerWords) {
      final regex = RegExp(r'\b' + filler + r'\b', caseSensitive: false);
      processed = processed
          .replaceAll(regex, '')
          .replaceAll(RegExp(r'\s+'), ' ');
    }

    // 5. Corregir errores comunes de Whisper en español
    final corrections = {
      r'\bésta\b': 'esta',
      r'\béste\b': 'este',
      r'\béso\b': 'eso',
      r'\beslábila\b': 'sílaba',
    };

    corrections.forEach((pattern, replacement) {
      processed = processed.replaceAll(
        RegExp(pattern, caseSensitive: false),
        replacement,
      );
    });

    return processed.trim();
  }

  /// Parar grabación sin transcribir (útil si el usuario cancela)
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _isRecording = false;
      _shouldStopRecording = true;

      final recordingPath = await _audioRecorder.stop();

      // Limpiar archivo
      if (recordingPath != null) {
        final file = File(recordingPath);
        await file
            .delete()
            .then((_) {
              _logger.i('Cancelled recording deleted');
            })
            .catchError((e) {
              _logger.w('Could not delete cancelled recording: $e');
              return null;
            });
      }

      _logger.i('🚫 Recording cancelled');
    } catch (e) {
      _logger.e('Error cancelling recording: $e');
    }
  }

  /// Obtener duración de grabación actual (en segundos)
  int getCurrentRecordingDuration() {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Limpiar recursos
  void dispose() {
    _audioRecorder.dispose();
    _previousTranscriptions.clear();
  }
}
