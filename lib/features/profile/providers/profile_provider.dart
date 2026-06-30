import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfileResponse> {
  @override
  Future<UserProfileResponse> build() async {
    final authUser = ref.watch(authStateProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const UserProfileResponse(
        id: '',
        displayName: 'Người dùng',
        email: '',
        nativeLanguage: 'vi',
        targetLanguage: 'en',
        cefrLevel: 'A1',
        isPremium: false,
      );
    }
    return _loadProfile(authUser);
  }

  Future<UserProfileResponse> _loadProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = user.uid;
    final localAvatarPathKey = 'profile.${uid}.local_avatar_path';
    final nativeLanguageKey = 'profile.${uid}.native_language';
    final targetLanguageKey = 'profile.${uid}.target_language';

    try {
      final profile =
          await ref.read(milingoApiServiceProvider).getUserProfile();
      return profile.copyWith(
        localAvatarPath: prefs.getString(localAvatarPathKey),
        nativeLanguage:
            profile.nativeLanguage ?? prefs.getString(nativeLanguageKey),
        targetLanguage:
            profile.targetLanguage ?? prefs.getString(targetLanguageKey),
      );
    } catch (_) {
      return UserProfileResponse(
        id: uid,
        displayName:
            user.displayName ?? user.email?.split('@').first ?? 'Người dùng',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        nativeLanguage: prefs.getString(nativeLanguageKey) ?? 'vi',
        targetLanguage: prefs.getString(targetLanguageKey) ?? 'en',
        cefrLevel: 'A1',
        isPremium: false,
        localAvatarPath: prefs.getString(localAvatarPathKey),
      );
    }
  }

  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadProfile(user));
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final current = state.valueOrNull;
    state = AsyncData((current ?? await _loadProfile(user)).copyWith(
      displayName: trimmed,
    ));

    try {
      await user.updateDisplayName(trimmed);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final localAvatarPathKey = 'profile.${uid}.local_avatar_path';
    final nativeLanguageKey = 'profile.${uid}.native_language';
    final targetLanguageKey = 'profile.${uid}.target_language';

    final prefs = await SharedPreferences.getInstance();
    if (nativeLanguage != null) {
      await prefs.setString(nativeLanguageKey, nativeLanguage);
    }
    if (targetLanguage != null) {
      await prefs.setString(targetLanguageKey, targetLanguage);
    }

    final current = state.valueOrNull ?? await _loadProfile(user);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final localAvatarPathKey = 'profile.${uid}.local_avatar_path';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localAvatarPathKey, path);
    final current = state.valueOrNull ?? await _loadProfile(user);
    state = AsyncData(current.copyWith(localAvatarPath: path));
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileResponse>(
  UserProfileNotifier.new,
);
