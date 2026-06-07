import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/routing/app_router.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  runApp(
    // ProviderScope enables Riverpod throughout the app
    const ProviderScope(
      child: MiLingoApp(),
    ),
  );
}

/// Root application widget
class MiLingoApp extends ConsumerStatefulWidget {
  const MiLingoApp({super.key});

  @override
  ConsumerState<MiLingoApp> createState() => _MiLingoAppState();
}

class _MiLingoAppState extends ConsumerState<MiLingoApp> {
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _lastHandledLink;

  @override
  void initState() {
    super.initState();
    _listenForPaymentReturnLinks();
  }

  void _listenForPaymentReturnLinks() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Payment return link error: $error');
      },
    );
  }

  void _handleIncomingLink(Uri uri) {
    if (_lastHandledLink == uri) return;
    _lastHandledLink = uri;

    final route = _paymentRouteFor(uri);
    if (route == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appRouterProvider).go(route);
    });
  }

  String? _paymentRouteFor(Uri uri) {
    if (uri.scheme == 'https' &&
        uri.host == Uri.parse(AppConstants.milingoWebBaseUrl).host) {
      return _knownPaymentRoute(uri.path);
    }

    if (uri.scheme == 'milingo' && uri.host == 'payment') {
      return _knownPaymentRoute('/payment${uri.path}');
    }

    return null;
  }

  String? _knownPaymentRoute(String path) {
    return switch (path) {
      AppConstants.paymentSuccessRoute => AppConstants.paymentSuccessRoute,
      AppConstants.paymentCancelRoute => AppConstants.paymentCancelRoute,
      _ => null,
    };
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
