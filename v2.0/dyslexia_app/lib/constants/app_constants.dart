import 'package:flutter/material.dart';

/// Constantes globales de la aplicación DyLexia Pro
class AppConstants {
  // API Configuration
  // PRODUCCIÓN: Cloud Run Backend
  static const String apiBaseUrl =
      "https://dyslexia-backend-868299789925.us-east4.run.app/api";
  static const Duration apiTimeout = Duration(seconds: 30);

  // Activity IDs
  static const String activitySequence = "sequence";
  static const String activityMirror = "mirror";
  static const String activityRhythm = "rhythm";
  static const String activitySpeed = "speed";
  static const String activityMemory = "memory";
  static const String activityText = "text";

  // Speech Recognition
  static const String speechLocale = "es-ES";
  static const Duration speechTimeout = Duration(seconds: 30);
  static const Duration speechPauseDuration = Duration(seconds: 3);

  // TTS Configuration
  static const String ttsLanguage = "es-ES";
  static const double ttsSpeechRate = 0.5;
  static const double ttsVolume = 1.0;
  static const double ttsPitch = 1.0;

  // Game Settings
  static const int speedActivityDuration = 30; // segundos
  static const int memorySequenceLength = 3;
  static const List<int> rhythmPattern = [1, 2, 1, 1];
  static const List<String> sequenceLetters = ["c", "a", "s", "a"];

  // Color Palette
  static const int primaryColorValue = 0xFF2196F3;
  static const int secondaryColorValue = 0xFF03DAC6;
  static const int errorColorValue = 0xFFB00020;
  static const int successColorValue = 0xFF4CAF50;

  // Color objects for easy use
  static const primaryColor = Color(primaryColorValue);
  static const secondaryColor = Color(secondaryColorValue);
  static const errorColor = Color(errorColorValue);
  static const successColor = Color(successColorValue);

  // Storage Keys
  static const String keyUserProfile = "user_profile";
  static const String keyActivityHistory = "activity_history";
  static const String keyStatistics = "statistics";
  static const String keyFirstLaunch = "first_launch";
  static const String keySoundEnabled = "sound_enabled";
  static const String keyVoiceEnabled = "voice_enabled";
  static const String keyUserId = "user_id";
  static const String keyIsLoggedIn = "is_logged_in";

  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration transitionDuration = Duration(milliseconds: 500);

  // Risk Levels
  static const double lowRiskThreshold = 0.3;
  static const double highRiskThreshold = 0.7;

  // UI
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 20.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 32.0;
}
