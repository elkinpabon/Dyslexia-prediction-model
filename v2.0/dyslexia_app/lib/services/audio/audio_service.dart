import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import '../../constants/app_constants.dart';

/// Servicio de audio, voz y reconocimiento de habla
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final _logger = Logger();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _ttsInitialized = false;
  bool _speechInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get speechAvailable => _speechInitialized;

  /// Inicializar TTS (Text-to-Speech) con voz natural mejorada
  Future<void> initializeTts() async {
    if (_ttsInitialized) return;

    try {
      // Configurar idioma español
      await _tts.setLanguage(AppConstants.ttsLanguage);

      // ===== CONFIGURACIÓN ÓPTIMA PARA VOZ NATURAL Y AGRADABLE =====

      // 1. Velocidad moderada, conversacional y cómoda
      await _tts.setSpeechRate(0.5); // Ritmo más natural y pausado

      // 2. Volumen óptimo (no al máximo para evitar distorsión)
      await _tts.setVolume(0.9);

      // 3. Pitch ligeramente más bajo para voz más cálida y natural
      await _tts.setPitch(0.95); // Voz más natural, agradable y humana

      // 4. iOS específico: Calidad mejorada
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );

      // 5. Android específico: Motor de síntesis mejorado
      await _tts.setEngine(
        "com.google.android.tts",
      ); // Motor de Google (más natural)

      // 6. Seleccionar la MEJOR voz disponible en español
      final voices = await _tts.getVoices;
      if (voices.isNotEmpty) {
        // Buscar voces en español
        final spanishVoices = voices.where((voice) {
          final locale = voice['locale'].toString().toLowerCase();
          return locale.contains('es-es') || // Español de España
              locale.contains('es-mx') || // Español de México
              locale.startsWith('es');
        }).toList();

        if (spanishVoices.isNotEmpty) {
          // PRIORIDAD DE VOCES (mejor a peor):
          // 1. Enhanced/Premium/Neural (voces de IA más naturales)
          // 2. Female (voces femeninas)
          // 3. Cualquier voz española disponible

          final preferredVoice = spanishVoices.firstWhere(
            (v) {
              final name = v['name'].toString().toLowerCase();
              return name.contains('neural') || // Voces IA (Google Neural)
                  name.contains('enhanced') || // Voces mejoradas
                  name.contains('premium') || // Voces premium
                  name.contains('wavenet') || // WaveNet de Google
                  name.contains('natural'); // Síntesis natural
            },
            orElse: () => spanishVoices.firstWhere(
              (v) => v['name'].toString().toLowerCase().contains('female'),
              orElse: () => spanishVoices.first,
            ),
          );

          await _tts.setVoice({
            'name': preferredVoice['name'],
            'locale': preferredVoice['locale'],
          });

          _logger.i('✓ Voz natural seleccionada: ${preferredVoice['name']}');
          _logger.i('  Locale: ${preferredVoice['locale']}');
        } else {
          _logger.w(
            '⚠ No se encontraron voces en español, usando voz por defecto',
          );
        }
      }

      _ttsInitialized = true;
      _logger.i('TTS initialized with enhanced natural voice');
    } catch (e) {
      _logger.e('Error initializing TTS: $e');
      _ttsInitialized = true; // Continuar con configuración por defecto
    }
  }

  /// Inicializar Speech Recognition
  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;

    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) => _logger.e('Speech error: $error'),
        onStatus: (status) => _logger.i('Speech status: $status'),
      );

      if (_speechInitialized) {
        final locales = await _speech.locales();
        _logger.i('Speech locales available: ${locales.length}');

        // Buscar español
        final spanishLocale = locales.firstWhere(
          (l) => l.localeId.startsWith('es'),
          orElse: () => locales.first,
        );
        _logger.i('Using locale: ${spanishLocale.localeId}');
      }

      return _speechInitialized;
    } catch (e) {
      _logger.e('Error initializing speech: $e');
      return false;
    }
  }

  /// Hablar texto (TTS) con pausas naturales
  Future<void> speak(String text, {double? rate, double? pitch}) async {
    if (!_ttsInitialized) await initializeTts();

    try {
      await _tts.stop(); // Detener cualquier reproducción previa

      // Forzar idioma español antes de hablar
      await _tts.setLanguage('es-ES');

      if (rate != null) await _tts.setSpeechRate(rate);
      if (pitch != null) await _tts.setPitch(pitch);

      // Mejorar pausas naturales agregando marcadores SSML
      final textWithPauses = _enhanceTextWithPauses(text);

      await _tts.speak(textWithPauses);
      _logger.i('Speaking: $textWithPauses');
    } catch (e) {
      _logger.e('Error speaking: $e');
    }
  }

  /// Mejora el texto con pausas naturales basadas en puntuación
  String _enhanceTextWithPauses(String text) {
    // Agregar pausas extra después de puntos para respiración natural
    String enhanced = text.replaceAll(
      '. ',
      '.  ',
    ); // Doble espacio = pausa más larga

    // Pausas ligeras después de comas
    enhanced = enhanced.replaceAll(', ', ',  ');

    // Pausas después de signos de interrogación/exclamación
    enhanced = enhanced.replaceAll('? ', '?  ');
    enhanced = enhanced.replaceAll('! ', '!  ');

    // Pausas después de dos puntos
    enhanced = enhanced.replaceAll(': ', ':  ');

    return enhanced;
  }

  /// Hablar con pausa al final (útil para instrucciones secuenciales)
  Future<void> speakWithPause(
    String text, {
    double? rate,
    double? pitch,
    Duration pause = const Duration(milliseconds: 800),
  }) async {
    await speak(text, rate: rate, pitch: pitch);

    // Esperar a que termine de hablar + pausa adicional
    await _waitForSpeechCompletion();
    await Future.delayed(pause);
  }

  /// Esperar a que el TTS termine de hablar
  Future<void> _waitForSpeechCompletion() async {
    // Configurar handler para detectar cuando termina
    bool isCompleted = false;

    _tts.setCompletionHandler(() {
      isCompleted = true;
    });

    // Esperar hasta que complete o timeout
    int attempts = 0;
    while (!isCompleted && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  /// Detener TTS
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      _logger.e('Error stopping speech: $e');
    }
  }

  /// Iniciar escucha (Speech-to-Text)
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Duration? timeout,
  }) async {
    if (!_speechInitialized) {
      final initialized = await initializeSpeech();
      if (!initialized) {
        _logger.e('Cannot start listening: Speech not initialized');
        return;
      }
    }

    if (_isListening) {
      _logger.w('Already listening');
      return;
    }

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: AppConstants.speechLocale,
        listenFor: timeout ?? AppConstants.speechTimeout,
        pauseFor: AppConstants.speechPauseDuration,
        cancelOnError: true,
        partialResults: onPartialResult != null,
      );

      _logger.i('Started listening...');
    } catch (e) {
      _logger.e('Error starting listening: $e');
      _isListening = false;
    }
  }

  /// Detener escucha
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _logger.i('Stopped listening');
    } catch (e) {
      _logger.e('Error stopping listening: $e');
    }
  }

  /// Reproducir sonido de efecto
  Future<void> playSound(String soundPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
      _logger.i('Playing sound: $soundPath');
    } catch (e) {
      _logger.e('Error playing sound: $e');
    }
  }

  /// Reproducir sonido de éxito
  Future<void> playSuccessSound() async {
    // Por ahora solo TTS, luego se pueden agregar archivos de audio
    await speak('¡Excelente!', rate: 0.6, pitch: 1.2);
  }

  /// Reproducir sonido de error
  Future<void> playErrorSound() async {
    await speak('Intenta de nuevo', rate: 0.5, pitch: 0.9);
  }

  /// Obtener nivel de audio actual
  double get currentSoundLevel =>
      _speech.lastRecognizedWords.isNotEmpty ? 1.0 : 0.0;

  /// Limpiar recursos
  void dispose() {
    _tts.stop();
    _speech.stop();
    _audioPlayer.dispose();
  }
}
