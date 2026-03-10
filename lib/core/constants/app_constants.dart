/// Core application constants for MiLingo
class AppConstants {
  // App Info
  static const String appName = 'MiLingo';
  static const String appVersion = '1.0.0';

  // API Keys (Store in environment variables or Firebase Remote Config in production)
  static const String geminiApiKey = 'AIzaSyBZtnLdJbq7eo2nx8SLytB2LpSVYUvyoPE';
  
  // PayOS Configuration
  static const String payOSBaseUrl = 'https://api-merchant.payos.vn';
  static const String payOSClientId = 'YOUR_PAYOS_CLIENT_ID';
  static const String payOSApiKey = 'YOUR_PAYOS_API_KEY';

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
  static const String homeRoute = '/home';
  static const String snapAndLearnRoute = '/snap-and-learn';
  static const String flashcardsRoute = '/flashcards';
  static const String profileRoute = '/profile';
  static const String leaderboardRoute = '/leaderboard';
}
