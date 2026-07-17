import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';

abstract interface class ScanHistoryDataSource {
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  });
}

class MilingoScanHistoryDataSource implements ScanHistoryDataSource {
  const MilingoScanHistoryDataSource(this._api);

  final MilingoApiService _api;

  @override
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  }) {
    return _api.getSnapHistory(limit: limit, cursor: cursor);
  }
}

final scanHistoryDataSourceProvider = Provider<ScanHistoryDataSource>((ref) {
  return MilingoScanHistoryDataSource(ref.watch(milingoApiServiceProvider));
});

final scanHistoryUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  return authUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
});

class ScanHistoryState {
  const ScanHistoryState({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<SnapHistoryItemResponse> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
}

class ScanHistoryNotifier extends AutoDisposeAsyncNotifier<ScanHistoryState> {
  static const _pageSize = 5;

  int _generation = 0;
  Object? _loadMoreToken;
  late ScanHistoryDataSource _dataSource;

  @override
  Future<ScanHistoryState> build() async {
    _generation++;
    _loadMoreToken = null;
    ref.onDispose(() {
      _generation++;
      _loadMoreToken = null;
    });

    final userId = ref.watch(scanHistoryUserIdProvider);
    if (userId == null) {
      return const ScanHistoryState(items: [], hasMore: false);
    }

    _dataSource = ref.watch(scanHistoryDataSourceProvider);
    final page = await _dataSource.fetchPage(limit: _pageSize);
    return ScanHistoryState(
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore && page.nextCursor != null,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (_loadMoreToken != null ||
        current == null ||
        !current.hasMore ||
        current.nextCursor == null) {
      return;
    }

    final requestGeneration = _generation;
    final requestToken = Object();
    _loadMoreToken = requestToken;
    state = AsyncData(
      ScanHistoryState(
        items: current.items,
        nextCursor: current.nextCursor,
        hasMore: current.hasMore,
        isLoadingMore: true,
      ),
    );

    try {
      final page = await _dataSource.fetchPage(
        limit: _pageSize,
        cursor: current.nextCursor,
      );
      if (requestGeneration != _generation || _loadMoreToken != requestToken) {
        return;
      }

      final seenIds = current.items.map((item) => item.id).toSet();
      final newItems = page.items.where((item) => seenIds.add(item.id));
      state = AsyncData(
        ScanHistoryState(
          items: List.unmodifiable([...current.items, ...newItems]),
          nextCursor: page.nextCursor,
          hasMore: page.hasMore && page.nextCursor != null,
        ),
      );
    } catch (error) {
      if (requestGeneration != _generation || _loadMoreToken != requestToken) {
        return;
      }
      state = AsyncData(
        ScanHistoryState(
          items: current.items,
          nextCursor: current.nextCursor,
          hasMore: current.hasMore,
          loadMoreError: error is MilingoApiException
              ? error.message
              : 'Không thể tải thêm lịch sử quét. Vui lòng thử lại.',
        ),
      );
    } finally {
      if (_loadMoreToken == requestToken) {
        _loadMoreToken = null;
      }
    }
  }
}

final scanHistoryProvider =
    AutoDisposeAsyncNotifierProvider<ScanHistoryNotifier, ScanHistoryState>(
        ScanHistoryNotifier.new);
