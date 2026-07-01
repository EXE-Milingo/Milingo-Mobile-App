import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/auth/services/google_auth_service.dart';

// ─────────────────────────────────────────────────────────
// Auth State Provider
// ─────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─────────────────────────────────────────────────────────
// Supported Languages Provider
//
// Fetches from the backend so the ChooseLanguage screen is
// always in sync with what the server actually supports.
// Falls back to an empty list (or you can add a fallback
// list) on error to avoid blocking the flow.
// ─────────────────────────────────────────────────────────

final supportedLanguagesProvider =
    FutureProvider<List<SupportedLanguage>>((ref) async {
  final api = ref.watch(milingoApiServiceProvider);
  return api.getSupportedLanguages();
});

// ─────────────────────────────────────────────────────────
// Init Profile helper
//
// Call this once after Firebase registration/login.
// Wraps the API call so callers get a user-friendly error.
// ─────────────────────────────────────────────────────────

class AuthService {
  const AuthService(this._api);
  final MilingoApiService _api;

  /// Initialises the user profile on the Milingo backend.
  /// Safe to call multiple times — the backend is idempotent.
  Future<void> initProfile({
    required String displayName,
    required String targetLanguage,
  }) async {
    await _api.initProfile(
      displayName: displayName,
      targetLanguage: targetLanguage,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(milingoApiServiceProvider));
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});
