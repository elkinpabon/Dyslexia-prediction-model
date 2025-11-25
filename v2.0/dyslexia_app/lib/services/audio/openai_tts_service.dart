import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio de síntesis de voz usando OpenAI Text-to-Speech (TTS)
/// - Voces ultra realistas y naturales en español latino
/// - Mejor pronunciación y entonación
/// - Múltiples opciones de voces (alloy, echo, fable, onyx, nova, shimmer)
///
/// VOCES DISPONIBLES:
/// - "alloy" - Voz balanceada, neutra
/// - "echo" - Voz resonante, expresiva
/// - "fable" - Voz clara, educativa (RECOMENDADA PARA NIÑOS)
/// - "onyx" - Voz profunda, seria
/// - "nova" - Voz cálida, acogedora (RECOMENDADA PARA ESTE PROYECTO)
/// - "shimmer" - Voz brillante, alegre
class OpenAiTtsService {
  static final OpenAiTtsService _instance = OpenAiTtsService._internal();
  factory OpenAiTtsService() => _instance;
  OpenAiTtsService._internal();

  final _logger = Logger();
  final _audioPlayer = AudioPlayer();

  // Configuración de OpenAI
  // IMPORTANTE: Cargar desde variables de entorno, NO hardcodear
  static const String _openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String _ttsEndpoint = 'https://api.openai.com/v1/audio/speech';

  // Modelo TTS
  static const String _model =
      'tts-1'; // tts-1 (rápido) o tts-1-hd (alta calidad)

  // Voz seleccionada - SHIMMER es brillante, alegre y muy infantil
  // Opciones: fable (educativa), nova (cálida), shimmer (brillante y alegre - MEJOR PARA NIÑOS)
  static const String _voice =
      'shimmer'; // Voz brillante y alegre, la mejor para niños entusiastas

  // Velocidad de habla (0.25 a 4.0)
  static const double _speed =
      0.9; // 0.9 = más lento y claro (mejor para niños)

  bool _isPlayingAudio = false;
  String? _lastAudioFilePath;

  bool get isPlayingAudio => _isPlayingAudio;

  /// Inicializar el servicio de TTS
  Future<void> initialize() async {
    try {
      // Configurar listeners del audio player
      _audioPlayer.onPlayerStateChanged.listen((state) {
        _isPlayingAudio = state == PlayerState.playing;
      });

      _logger.i('✓ OpenAI TTS Service initialized');
      _logger.i('   🎙️ Voz seleccionada: $_voice');
      _logger.i('   ⚡ Modelo: $_model');
      _logger.i('   🎯 Velocidad: $_speed (0.9 = más lento y claro)');
    } catch (e) {
      _logger.e('Error initializing OpenAI TTS: $e');
    }
  }

  /// Sintetizar texto a voz y reproducir inmediatamente
  /// [text]: Texto a sintetizar (máx 4096 caracteres)
  /// [waitForCompletion]: Si es true, espera a que termine de reproducir
  Future<bool> speak(String text, {bool waitForCompletion = true}) async {
    if (text.isEmpty) {
      _logger.w('Cannot speak: empty text');
      return false;
    }

    // Validar longitud de texto
    if (text.length > 4096) {
      _logger.w('Text too long for OpenAI TTS (max 4096 chars), truncating...');
      text = text.substring(0, 4096);
    }

    try {
      final preview = text.length > 50 ? text.substring(0, 50) + '...' : text;
      _logger.i('🎤 Speaking: "$preview"');

      // Detener cualquier audio previo
      await _audioPlayer.stop();
      _isPlayingAudio = true;

      // Obtener audio de OpenAI
      final audioFile = await _synthesizeText(text);
      if (audioFile == null) {
        return false;
      }

      // Guardar ruta para limpieza posterior
      _lastAudioFilePath = audioFile.path;

      // Reproducir audio
      await _audioPlayer.play(DeviceFileSource(audioFile.path));

      // Esperar a que termine si lo solicitan
      if (waitForCompletion) {
        await Future.delayed(const Duration(milliseconds: 500));
        while (_isPlayingAudio) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return true;
    } catch (e) {
      _logger.e('Error in speak: $e');
      _isPlayingAudio = false;
      return false;
    }
  }

  /// Sintetizar texto a archivo de audio sin reproducir
  /// Útil para guardar audio para reproducción posterior
  Future<File?> synthesizeToFile(String text, {String? outputPath}) async {
    if (text.isEmpty) {
      _logger.w('Cannot synthesize: empty text');
      return null;
    }

    try {
      final audioFile = await _synthesizeText(text, customPath: outputPath);
      return audioFile;
    } catch (e) {
      _logger.e('Error synthesizing to file: $e');
      return null;
    }
  }

  /// Detener reproducción actual
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlayingAudio = false;
      _logger.i('Audio stopped');
    } catch (e) {
      _logger.e('Error stopping audio: $e');
    }
  }

  /// Realizar la síntesis con OpenAI API
  Future<File?> _synthesizeText(String text, {String? customPath}) async {
    try {
      // Preparar ruta de guardado
      final dir = await getTemporaryDirectory();
      final outputPath =
          customPath ??
          '${dir.path}/openai_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';

      _logger.i('📊 Enviando solicitud a OpenAI TTS API...');
      final preview = text.length > 50 ? text.substring(0, 50) + '...' : text;
      _logger.i('   Texto: "$preview"');
      _logger.i('   Longitud: ${text.length} caracteres');

      // Realizar solicitud POST a OpenAI
      final response = await http
          .post(
            Uri.parse(_ttsEndpoint),
            headers: {
              'Authorization': 'Bearer $_openAiApiKey',
              'Content-Type': 'application/json',
            },
            body: _buildRequestBody(text),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('TTS synthesis timeout (30s)');
            },
          );

      if (response.statusCode != 200) {
        _logger.e('OpenAI TTS Error: ${response.statusCode}');
        _logger.e('Response: ${response.body}');

        // Log de error detallado
        if (response.statusCode == 401) {
          _logger.e('❌ API Key inválida o expirada');
        } else if (response.statusCode == 429) {
          _logger.e('❌ Rate limit excedido');
        } else if (response.statusCode == 400) {
          _logger.e('❌ Texto no válido o parámetros incorrectos');
        }

        return null;
      }

      // Guardar audio en archivo
      final audioFile = File(outputPath);
      await audioFile.writeAsBytes(response.bodyBytes);

      _logger.i('✓ Audio sintetizado exitosamente');
      _logger.i('   Tamaño: ${response.bodyBytes.length} bytes');
      _logger.i('   Ruta: $outputPath');

      return audioFile;
    } on TimeoutException catch (e) {
      _logger.e('Timeout: $e');
      return null;
    } catch (e) {
      _logger.e('Error synthesizing text: $e');
      return null;
    }
  }

  /// Construir body JSON para la solicitud
  String _buildRequestBody(String text) {
    return '''{
      "model": "$_model",
      "input": "${_escapeJson(text)}",
      "voice": "$_voice",
      "speed": $_speed
    }''';
  }

  /// Escapar caracteres especiales para JSON
  String _escapeJson(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Limpiar archivos de audio temporal
  Future<void> cleanup() async {
    try {
      if (_lastAudioFilePath != null) {
        final file = File(_lastAudioFilePath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('✓ Temporary audio file deleted');
        }
      }
    } catch (e) {
      _logger.e('Error cleaning up audio: $e');
    }
  }

  /// Obtener información del servicio
  Map<String, String> getServiceInfo() {
    return {
      'Service': 'OpenAI Text-to-Speech',
      'Model': _model,
      'Voice': _voice,
      'Speed': _speed.toString(),
      'Max Text Length': '4096 characters',
      'Audio Format': 'MP3',
      'Status': _isPlayingAudio ? 'Playing' : 'Idle',
    };
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
