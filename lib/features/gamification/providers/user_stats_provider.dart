import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';

// ─────────────────────────────────────────────────────────
// UserStatsNotifier — fetch từ backend, cache trong memory
// ─────────────────────────────────────────────────────────

class UserStatsNotifier extends AsyncNotifier<UserStatsResponse> {
  @override
  Future<UserStatsResponse> build() async {
    return _fetchFromBackend();
  }

  Future<UserStatsResponse> _fetchFromBackend() async {
    final api = ref.read(milingoApiServiceProvider);
    return api.getUserStats();
  }

  /// Gọi khi user mở deck/flashcard screen.
  /// Ghi nhận học hôm nay và cập nhật streak.
  Future<void> recordStudy() async {
    final api = ref.read(milingoApiServiceProvider);
    try {
      final updated = await api.recordFlashcardStudy();
      state = AsyncData(updated);
    } catch (_) {
      // Lỗi mạng không làm crash UI — giữ nguyên state cũ
    }
  }

  /// Cộng coins vào state ngay sau snap (optimistic update).
  /// Backend đã lưu rồi — chỉ cần update UI.
  void addCoinsOptimistic(int amount) {
    final current = state.valueOrNull;
    if (current == null || amount <= 0) return;
    state = AsyncData(UserStatsResponse(
      coins: current.coins + amount,
      currentStreak: current.currentStreak,
      totalPoints: current.totalPoints + amount,
      lastStudyDate: current.lastStudyDate,
    ));
  }

  /// Refresh từ backend (gọi khi cần đồng bộ chắc chắn).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFromBackend);
  }
}

// ─────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────

final userStatsProvider =
    AsyncNotifierProvider<UserStatsNotifier, UserStatsResponse>(
  UserStatsNotifier.new,
);

/// Sync shim — dùng trong widget, không cần handle loading riêng.
/// Trả về giá trị mặc định 0 khi đang load.
final userStatsValueProvider = Provider<UserStatsResponse>((ref) {
  return ref.watch(userStatsProvider).valueOrNull ??
      const UserStatsResponse(
        coins: 0,
        currentStreak: 0,
        totalPoints: 0,
      );
});
