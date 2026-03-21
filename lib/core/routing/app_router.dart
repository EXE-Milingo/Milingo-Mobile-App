import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/snap_and_learn/screens/snap_and_learn_screen.dart';
import 'package:milingo/features/home/screens/simple_home_screen.dart';
import 'package:milingo/features/splash/screens/splash_screen.dart';

part 'app_router.g.dart';

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
        builder: (context, state) => const AuthScreen(),
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

    // Redirect logic (e.g., auth guard)
    // Uncomment and implement when auth provider is ready
    // redirect: (context, state) {
    //   final isAuthenticated = ref.read(authStateProvider);
    //   final isAuthRoute = state.matchedLocation == AppConstants.authRoute;
    //
    //   if (!isAuthenticated && !isAuthRoute) {
    //     return AppConstants.authRoute;
    //   }
    //   return null;
    // },
  );
}

// SplashScreen is now imported from features/splash folder

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Auth Screen - TODO')),
    );
  }
}

// SimpleHomeScreen is now imported from features folder

// SnapAndLearnScreen is now imported from features folder

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Flashcards Screen - TODO')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Screen - TODO')),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Leaderboard Screen - TODO')),
    );
  }
}
