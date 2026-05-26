import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/auth/screens/choose_language_screen.dart';
import 'package:milingo/features/auth/screens/forgot_password_screen.dart';
import 'package:milingo/features/auth/screens/login_screen.dart';
import 'package:milingo/features/auth/screens/register_screen.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';
import 'package:milingo/features/flashcards/screens/all_categories_screen.dart';
import 'package:milingo/features/flashcards/screens/deck_screen.dart';
import 'package:milingo/features/flashcards/screens/exam_screen.dart';
import 'package:milingo/features/flashcards/screens/flashcards_screen.dart';
import 'package:milingo/features/flashcards/screens/vocab_detail_screen.dart';
import 'package:milingo/features/home/screens/simple_home_screen.dart';
import 'package:milingo/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:milingo/features/profile/screens/profile_screen.dart';
import 'package:milingo/features/snap_and_learn/screens/snap_and_learn_screen.dart';
import 'package:milingo/features/splash/screens/splash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

const _publicRoutes = {
  AppConstants.splashRoute,
  AppConstants.authRoute,
  AppConstants.registerRoute,
  AppConstants.forgotPasswordRoute,
};

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.authRoute,
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.chooseLanguageRoute,
        name: 'choose-language',
        builder: (context, state) => const ChooseLanguageScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const SimpleHomeScreen(),
      ),
      GoRoute(
        path: AppConstants.snapAndLearnRoute,
        name: 'snap-and-learn',
        builder: (context, state) => const SnapAndLearnScreen(),
      ),
      GoRoute(
        path: AppConstants.flashcardsRoute,
        name: 'flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),
      GoRoute(
        path: AppConstants.allCategoriesRoute,
        name: 'all-categories',
        builder: (context, state) => const AllCategoriesScreen(),
      ),
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
      GoRoute(
        path: AppConstants.deckRoute,
        name: 'deck',
        builder: (context, state) {
          final arg = state.extra;
          if (arg is DeckArg) {
            return DeckScreen(deck: arg);
          }

          return const DeckScreen(
            deck: DeckArg(
              id: 'nouns',
              name: 'Nouns',
              nameVi: 'Danh từ',
              total: 150,
              learned: 15,
              emoji: '📦',
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.vocabDetailRoute,
        name: 'vocabulary-detail',
        builder: (context, state) {
          final arg = state.extra;
          if (arg is VocabDetailArg) {
            return VocabDetailScreen(arg: arg);
          }

          return const VocabDetailScreen(
            arg: VocabDetailArg(
              deckId: '',
              deckName: 'Từ vựng',
              entry: FlashcardEntry(
                id: '',
                english: 'Vocabulary',
                translation: 'Từ vựng',
                pronunciation: '',
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.leaderboardRoute,
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      if (_publicRoutes.contains(location)) return null;
      if (user == null) return AppConstants.authRoute;

      return null;
    },
  );
}
