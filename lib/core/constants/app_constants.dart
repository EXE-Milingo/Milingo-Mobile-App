import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Core application constants for MiLingo
class AppConstants {
  // App Info
  static const String appName = 'MiLingo';
  static const String appVersion = '1.0.0';

  // API Keys (Store in environment variables in production)
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // PayOS Configuration
  static const String payOSBaseUrl = 'https://api-merchant.payos.vn';
  static String get payOSClientId =>
      dotenv.env['PAYOS_CLIENT_ID'] ?? 'YOUR_PAYOS_CLIENT_ID';
  static String get payOSApiKey =>
      dotenv.env['PAYOS_API_KEY'] ?? 'YOUR_PAYOS_API_KEY';

  // Supported Languages
  static const List<String> supportedLanguages = [
    'en', // English
    'vi', // Vietnamese
    'ja', // Japanese
    'ko', // Korean
    'zh', // Chinese
    'es', // Spanish
    'fr', // French
    'de', // German
  ];

  // Gamification
  static const int dailyStreakCoins = 10;
  static const int snapAndLearnCoins = 5;
  static const int flashcardCompleteCoins = 3;

  // Image Processing
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double imageQuality = 0.8;

  // Routes (will be defined in routing)
  static const String splashRoute = '/';
  static const String authRoute = '/auth';
  static const String registerRoute = '/register';
  static const String chooseLanguageRoute = '/choose-language';
  static const String homeRoute = '/home';
  static const String snapAndLearnRoute = '/snap-and-learn';
  static const String flashcardsRoute = '/flashcards';
  static const String deckRoute = '/flashcards/deck';
  static const String examRoute = '/flashcards/exam';
  static const String profileRoute = '/profile';
  static const String allCategoriesRoute = '/flashcards/all-categories';
  static const String leaderboardRoute = '/leaderboard';
}
