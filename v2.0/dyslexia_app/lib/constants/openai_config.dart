/// NUNCA incluir en código fuente en repositorio público
/// API Key debe ser cargada desde variables de entorno o archivo .env
class OpenAiConfig {
  // API Key para OpenAI (Whisper STT + TTS)
  // IMPORTANTE: Cargar desde variables de entorno, NO hardcodear
  static const String apiKey = 'YOUR_OPENAI_API_KEY_HERE';

  // ===== ENDPOINTS DE OPENAI =====

  // Speech-to-Text (Whisper API) - para transcribir audio
  static const String whisperEndpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  // Text-to-Speech API - para sintetizar voz (NUEVO)
  static const String ttsEndpoint = 'https://api.openai.com/v1/audio/speech';

  // ===== CONFIGURACIÓN STT (WHISPER) =====

  // Modelo a utilizar
  static const String sttModel = 'whisper-1';

  // Idioma predeterminado (español)
  static const String defaultLanguage = 'es';

  // Configuración de grabación
  static const int sampleRate = 16000; // Hz
  static const int bitRate = 128000; // bps
  static const int numChannels = 1; // Mono

  // Timeouts STT
  static const Duration transcriptionTimeout = Duration(seconds: 60);
  static const Duration recordingInitTimeout = Duration(seconds: 5);

  // Límites STT
  static const int maxRecordingDuration = 300; // segundos (5 minutos máximo)
  static const int minRecordingSize =
      1000; // bytes (más pequeño = probablemente ruido)

  // ===== CONFIGURACIÓN TTS (TEXT-TO-SPEECH) =====

  // Modelo TTS
  static const String ttsModel =
      'tts-1'; // 'tts-1' (rápido) o 'tts-1-hd' (alta calidad)

  // Voces disponibles en TTS
  static const String ttsVoice =
      'nova'; // alloy, echo, fable, onyx, nova, shimmer

  // Velocidad de habla (0.25 a 4.0, default 1.0)
  static const double ttsSpeed = 0.9; // 0.9 = más conversacional

  // Formato de salida TTS
  static const String ttsFormat = 'mp3'; // mp3, opus, aac, flac

  // Timeouts TTS
  static const Duration ttsTimeout = Duration(seconds: 30);
}
