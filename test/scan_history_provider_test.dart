import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/flashcards/providers/scan_history_provider.dart';

void main() {
  test('loads five items first and only one next page concurrently', () async {
    final source = _FakeScanHistoryDataSource([
      _page(0, nextCursor: 'page-2', hasMore: true),
      _page(5, hasMore: false),
    ]);
    final container = ProviderContainer(
      overrides: [
        scanHistoryDataSourceProvider.overrideWithValue(source),
        scanHistoryUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    final subscription = container.listen(
      scanHistoryProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final first = await container.read(scanHistoryProvider.future);
    expect(first.items, hasLength(5));
    expect(source.requests, [(limit: 5, cursor: null)]);

    final notifier = container.read(scanHistoryProvider.notifier);
    await Future.wait([notifier.loadMore(), notifier.loadMore()]);

    final loaded = container.read(scanHistoryProvider).requireValue;
    expect(loaded.items, hasLength(10));
    expect(loaded.hasMore, isFalse);
    expect(source.requests, [
      (limit: 5, cursor: null),
      (limit: 5, cursor: 'page-2'),
    ]);
  });

  test('does not request another page after the end', () async {
    final source = _FakeScanHistoryDataSource([_page(0, hasMore: false)]);
    final container = ProviderContainer(
      overrides: [
        scanHistoryDataSourceProvider.overrideWithValue(source),
        scanHistoryUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    final subscription = container.listen(
      scanHistoryProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    await container.read(scanHistoryProvider.future);
    await container.read(scanHistoryProvider.notifier).loadMore();

    expect(source.requests, [(limit: 5, cursor: null)]);
  });
}

class _FakeScanHistoryDataSource implements ScanHistoryDataSource {
  _FakeScanHistoryDataSource(this.pages);

  final List<SnapHistoryPageResponse> pages;
  final List<({int limit, String? cursor})> requests = [];
  int _index = 0;

  @override
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  }) async {
    requests.add((limit: limit, cursor: cursor));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return pages[_index++];
  }
}

SnapHistoryPageResponse _page(
  int start, {
  required bool hasMore,
  String? nextCursor,
}) {
  return SnapHistoryPageResponse(
    items: List.generate(
      5,
      (index) => SnapHistoryItemResponse(
        id: 'word-${start + index}',
        keyword: 'Word ${start + index}',
        translation: 'Nghĩa ${start + index}',
        pronunciation: '',
        exampleSentence: '',
        createdAt: DateTime.utc(2026, 7, 17).subtract(
          Duration(minutes: start + index),
        ),
      ),
    ),
    nextCursor: nextCursor,
    hasMore: hasMore,
  );
}
