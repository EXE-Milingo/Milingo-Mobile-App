import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nativeLanguageKey = 'profile.native_language';
const _targetLanguageKey = 'profile.target_language';
const _localAvatarPathKey = 'profile.local_avatar_path';

class UserProfileNotifier extends AsyncNotifier<UserProfileResponse> {
  @override
  Future<UserProfileResponse> build() async {
    return _loadProfile();
  }

  Future<UserProfileResponse> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    try {
      final profile =
          await ref.read(milingoApiServiceProvider).getUserProfile();
      return profile.copyWith(
        localAvatarPath: prefs.getString(_localAvatarPathKey),
        nativeLanguage:
            profile.nativeLanguage ?? prefs.getString(_nativeLanguageKey),
        targetLanguage:
            profile.targetLanguage ?? prefs.getString(_targetLanguageKey),
      );
    } catch (_) {
      return UserProfileResponse(
        id: user?.uid ?? '',
        displayName:
            user?.displayName ?? user?.email?.split('@').first ?? 'Người dùng',
        email: user?.email ?? '',
        photoUrl: user?.photoURL,
        nativeLanguage: prefs.getString(_nativeLanguageKey) ?? 'vi',
        targetLanguage: prefs.getString(_targetLanguageKey) ?? 'en',
        cefrLevel: 'A1',
        isPremium: false,
        localAvatarPath: prefs.getString(_localAvatarPathKey),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadProfile);
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull;
    state = AsyncData((current ?? await _loadProfile()).copyWith(
      displayName: trimmed,
    ));

    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(trimmed);
      final updated = await ref
          .read(milingoApiServiceProvider)
          .updateUserProfile(displayName: trimmed);
      state = AsyncData(updated.copyWith(
        localAvatarPath: state.valueOrNull?.localAvatarPath,
      ));
    } catch (_) {
      // Keep the optimistic local value. The backend contract is documented
      // in MODULE_ANALYSIS.md so the server can catch up without blocking UI.
    }
  }

  Future<void> updateLanguages({
    String? nativeLanguage,
    String? targetLanguage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (nativeLanguage != null) {
      await prefs.setString(_nativeLanguageKey, nativeLanguage);
    }
    if (targetLanguage != null) {
      await prefs.setString(_targetLanguageKey, targetLanguage);
    }

    final current = state.valueOrNull ?? await _loadProfile();
    state = AsyncData(current.copyWith(
      nativeLanguage: nativeLanguage ?? current.nativeLanguage,
      targetLanguage: targetLanguage ?? current.targetLanguage,
    ));

    try {
      final updated =
          await ref.read(milingoApiServiceProvider).updateUserProfile(
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
              );
      state = AsyncData(updated.copyWith(
        localAvatarPath: state.valueOrNull?.localAvatarPath,
      ));
    } catch (_) {
      // SharedPreferences is the offline source of truth until PATCH /users/me
      // is implemented by the backend.
    }
  }

  Future<void> setLocalAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localAvatarPathKey, path);
    final current = state.valueOrNull ?? await _loadProfile();
    state = AsyncData(current.copyWith(localAvatarPath: path));
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileResponse>(
  UserProfileNotifier.new,
);
