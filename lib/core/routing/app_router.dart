import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/snap_and_learn/screens/snap_and_learn_screen.dart';
import 'package:milingo/features/home/screens/simple_home_screen.dart';
import 'package:milingo/features/splash/screens/splash_screen.dart';
import 'package:milingo/features/auth/screens/login_screen.dart';
import 'package:milingo/features/auth/screens/register_screen.dart';
import 'package:milingo/features/auth/screens/choose_language_screen.dart';
import 'package:milingo/features/profile/screens/profile_screen.dart';
import 'package:milingo/features/flashcards/screens/flashcards_screen.dart';
import 'package:milingo/features/flashcards/screens/all_categories_screen.dart';
import 'package:milingo/features/flashcards/screens/deck_screen.dart';
import 'package:milingo/features/flashcards/screens/exam_screen.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/leaderboard/screens/leaderboard_screen.dart';

part 'app_router.g.dart';

/// Routes that do NOT require authentication.
const _publicRoutes = {
  AppConstants.splashRoute,
  AppConstants.authRoute,
  AppConstants.registerRoute,
};

/// Router provider - manages app navigation
/// Uses Riverpod for state-aware routing (can check auth state, etc.)
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
    routes: [
      // Splash/Onboarding Route
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppConstants.authRoute,
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
      ),

      // Register Route
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Choose Language Route (post-registration)
      GoRoute(
        path: AppConstants.chooseLanguageRoute,
        name: 'choose-language',
        builder: (context, state) => const ChooseLanguageScreen(),
      ),

      // Home Route (Main Dashboard)
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const SimpleHomeScreen(),
      ),

      // Snap & Learn Feature
      GoRoute(
        path: AppConstants.snapAndLearnRoute,
        name: 'snap-and-learn',
        builder: (context, state) => const SnapAndLearnScreen(),
      ),

      // Flashcards Feature
      GoRoute(
        path: AppConstants.flashcardsRoute,
        name: 'flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),

      // All Categories Route
      GoRoute(
        path: AppConstants.allCategoriesRoute,
        name: 'all-categories',
        builder: (context, state) => const AllCategoriesScreen(),
      ),

      // Exam Route
      GoRoute(
        path: AppConstants.examRoute,
        name: 'exam',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return ExamScreen(
            langCode: extra?['langCode'] ?? 'en',
            langName: extra?['langName'] ?? 'English',
          );
        },
      ),

      // Individual Deck
      GoRoute(
        path: AppConstants.deckRoute,
        name: 'deck',
        builder: (context, state) {
          final arg = state.extra;
          if (arg is DeckArg) {
            return DeckScreen(deck: arg);
          }
          // Fallback if navigated without extra
          return DeckScreen(deck: const DeckArg(
            id: 'nouns', name: 'Nouns', nameVi: 'Danh từ',
            total: 150, learned: 15, emoji: '📦',
          ));
        },
      ),

      // Profile Route
      GoRoute(
        path: AppConstants.profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Leaderboard Route
      GoRoute(
        path: AppConstants.leaderboardRoute,
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),

    // Auth guard — redirect to /auth if user is not logged in
    // and trying to access a protected route.
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      // Allow public routes without auth
      if (_publicRoutes.contains(location)) return null;

      // Not logged in → send to login
      if (user == null) return AppConstants.authRoute;

      // Logged in + going to auth page → send to home instead
      // (this case is already covered above, but kept for clarity)

      return null; // no redirect needed
    },
  );
}

