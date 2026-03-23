import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/routing/app_router.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
/// MiLingo - AI-Powered Language Learning App
///
/// Architecture: Feature-First with Clean Architecture principles
/// State Management: Riverpod
/// Routing: GoRouter
/// Backend: Firebase (Auth, Firestore)
/// AI: Google Gemini API
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  // Note: Uncomment when Firebase is configured with google-services.json / GoogleService-Info.plist
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // ProviderScope enables Riverpod throughout the app
    const ProviderScope(
      child: MiLingoApp(),
    ),
  );
}

/// Root application widget
class MiLingoApp extends ConsumerWidget {
  const MiLingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the router configuration from Riverpod
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App Configuration
      title: 'MiLingo',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Routing with GoRouter
      routerConfig: router,

      // Localization (for future multi-language UI support)
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', ''), // English
      //   Locale('vi', ''), // Vietnamese
      // ],
    );
  }
}
