import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';

class LeaderboardState {
  const LeaderboardState({
    required this.users,
    required this.currentUser,
    required this.hasMore,
    required this.isLoadingMore,
    required this.offset,
  });

  final List<LeaderboardUser> users;
  final LeaderboardUser? currentUser;
  final bool hasMore;
  final bool isLoadingMore;
  final int offset;

  LeaderboardState copyWith({
    List<LeaderboardUser>? users,
    LeaderboardUser? currentUser,
    bool? hasMore,
    bool? isLoadingMore,
    int? offset,
  }) {
    return LeaderboardState(
      users: users ?? this.users,
      currentUser: currentUser ?? this.currentUser,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      offset: offset ?? this.offset,
    );
  }
}

class LeaderboardNotifier extends AsyncNotifier<LeaderboardState> {
  @override
  Future<LeaderboardState> build() async {
    final api = ref.watch(milingoApiServiceProvider);
    final response = await api.getLeaderboard(limit: 5, offset: 0);
    return LeaderboardState(
      users: response.users,
      currentUser: response.currentUser,
      hasMore: response.users.length == 5,
      isLoadingMore: false,
      offset: response.users.length,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    // Set loading more
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final api = ref.read(milingoApiServiceProvider);
      final response =
          await api.getLeaderboard(limit: 5, offset: current.offset);

      state = AsyncData(current.copyWith(
        users: [...current.users, ...response.users],
        currentUser: response.currentUser ?? current.currentUser,
        hasMore: response.users.length == 5,
        isLoadingMore: false,
        offset: current.offset + response.users.length,
      ));
    } catch (e, stack) {
      // Revert loading more state
      final currentData = state.valueOrNull;
      if (currentData != null) {
        state = AsyncData(currentData.copyWith(isLoadingMore: false));
      } else {
        state = AsyncError(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

// ── Providers ────────────────────────────────────────────────────────

final leaderboardNotifierProvider =
    AsyncNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  LeaderboardNotifier.new,
);

final topThreeLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardUser>>((ref) async {
  final api = ref.watch(milingoApiServiceProvider);
  final response = await api.getLeaderboard(limit: 3, offset: 0);
  return response.users;
});
