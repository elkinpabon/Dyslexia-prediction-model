import 'dart:math';
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

  /// Inicializar TTS (Text-to-Speech) con voz natural ESPAÑOL LATINO realista
  Future<void> initializeTts() async {
    if (_ttsInitialized) return;

    try {
      // ===== CONFIGURACIÓN PARA ESPAÑOL LATINO REALISTA =====

      // 1. Configurar idioma español (latino preferentemente)
      await _tts.setLanguage(
        'es-MX',
      ); // Español de México (más latino y natural)

      // 2. Velocidad CONVERSACIONAL natural (0.45 = 55 palabras/min, ideal para niños)
      await _tts.setSpeechRate(0.45);

      // 3. Volumen óptimo (0.85 = audible pero no distorsionado)
      await _tts.setVolume(0.85);

      // 4. Pitch NATURAL para voz femenina cálida y acogedora (1.0 = natural)
      await _tts.setPitch(1.0);

      // 5. iOS específico: Configuración de audio de alta calidad
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );

      // 6. Android específico: Motor de síntesis avanzado Google
      await _tts.setEngine('com.google.android.tts');

      // 7. SELECCIONAR MEJOR VOZ DISPONIBLE EN ESPAÑOL LATINO
      final voices = await _tts.getVoices;
      _logger.i('📢 Voces disponibles: ${voices.length}');

      if (voices.isNotEmpty) {
        // Filtrar SOLO voces en español (preferir latino)
        final spanishVoices = voices.where((voice) {
          final locale = voice['locale'].toString().toLowerCase();

          // Prioridad: es-mx > es-ar > es-co > es-es > es genérico
          return locale.contains('es-mx') || // 🥇 México (MÁS LATINO)
              locale.contains('es-ar') || // 🥈 Argentina
              locale.contains('es-co') || // 🥉 Colombia
              locale.contains('es-cl') || // Chile
              locale.contains('es-pe') || // Perú
              locale.contains('es-ve') || // Venezuela
              locale.contains('es-es') || // España (última opción)
              locale.startsWith('es');
        }).toList();

        if (spanishVoices.isNotEmpty) {
          _logger.i('✓ Voces en español encontradas: ${spanishVoices.length}');

          // PRIORIDAD INTELIGENTE DE SELECCIÓN:
          // 1️⃣ Google Neural Voices (voces IA más naturales)
          // 2️⃣ Female voices (más acogedoras para niños)
          // 3️⃣ Cualquier voz disponible

          final preferredVoice = _selectBestSpanishVoice(spanishVoices);

          await _tts.setVoice({
            'name': preferredVoice['name'],
            'locale': preferredVoice['locale'],
          });

          _logger.i('✨ VOZ SELECCIONADA: ${preferredVoice['name']}');
          _logger.i('   Idioma: ${preferredVoice['locale']}');
          _logger.i('   Región: ${_getRegionName(preferredVoice["locale"])}');
        } else {
          _logger.w('⚠️ No se encontraron voces en español, usando defecto');
          // Fallback a español genérico
          await _tts.setLanguage('es');
        }
      }

      _ttsInitialized = true;
      _logger.i('🎙️ TTS INICIALIZADO - Voz natural español latino');
    } catch (e) {
      _logger.e('Error initializing TTS: $e');
      _ttsInitialized = true; // Continuar con configuración por defecto
    }
  }

  /// Selecciona la mejor voz disponible en español
  /// Prioriza: Neural > Premium > Enhanced > Female > Default
  Map<String, dynamic> _selectBestSpanishVoice(List<dynamic> voices) {
    // Buscar voces con máxima prioridad
    for (final voice in voices) {
      final name = voice['name'].toString().toLowerCase();

      // 🥇 Máxima prioridad: Voces Neural/Premium (IA más natural)
      if (name.contains('neural') ||
          name.contains('premium') ||
          name.contains('wavenet')) {
        _logger.i('   📍 Tipo: Neural/Premium (IA avanzada)');
        return voice;
      }
    }

    // 🥈 Segunda prioridad: Voces femeninas (más acogedoras)
    for (final voice in voices) {
      final name = voice['name'].toString().toLowerCase();
      if (name.contains('female') || name.contains('mujer')) {
        _logger.i('   📍 Tipo: Voz femenina');
        return voice;
      }
    }

    // 🥉 Tercera prioridad: Cualquier voz disponible
    _logger.i('   📍 Tipo: Voz genérica');
    return voices.first;
  }

  /// Obtiene el nombre descriptivo de la región
  String _getRegionName(String locale) {
    final l = locale.toLowerCase();
    if (l.contains('es-mx')) return '🇲🇽 México (Latino)';
    if (l.contains('es-ar')) return '🇦🇷 Argentina (Latino)';
    if (l.contains('es-co')) return '🇨🇴 Colombia (Latino)';
    if (l.contains('es-cl')) return '🇨🇱 Chile (Latino)';
    if (l.contains('es-pe')) return '🇵🇪 Perú (Latino)';
    if (l.contains('es-ve')) return '🇻🇪 Venezuela (Latino)';
    if (l.contains('es-es')) return '🇪🇸 España';
    return '🌐 Español genérico';
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

  /// Hablar texto con flutter_tts LOCAL (sin API)
  /// ✅ Sin latencia de servidor
  /// ✅ Voz natural y realista
  /// ✅ Optimizado para niños
  Future<void> speak(String text, {double? rate, double? pitch}) async {
    if (text.isEmpty) {
      _logger.w('Cannot speak: empty text');
      return;
    }

    try {
      // Aplicar configuración personalizada si se proporciona
      if (rate != null) {
        await _tts.setSpeechRate(rate);
      }
      if (pitch != null) {
        await _tts.setPitch(pitch);
      }

      // Hablar con TTS LOCAL (sin API)
      await _tts.speak(text);

      _logger.i(
        '🎙️ Speaking (local TTS): ${text.substring(0, min(text.length, 50))}',
      );
    } catch (e) {
      _logger.e('Error speaking: $e');
    }
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
    await Future.delayed(pause);
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
