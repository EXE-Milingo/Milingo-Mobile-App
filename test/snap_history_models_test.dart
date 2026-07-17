import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';

void main() {
  test('parses a scan history page from the backend contract', () {
    final page = SnapHistoryPageResponse.fromJson({
      'items': [
        {
          'id': 'word-1',
          'snap_group_id': 'snap-1',
          'keyword': 'Dog',
          'translation': 'Chó',
          'pronunciation': '/dɒɡ/',
          'example_sentence': 'The dog is friendly.',
          'related_words': [
            {
              'keyword': 'Puppy',
              'translation': 'Chó con',
              'pronunciation': '/ˈpʌpi/',
            },
          ],
          'created_at': '2026-07-17T03:30:00Z',
        },
      ],
      'next_cursor': 'opaque-cursor',
      'has_more': true,
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.id, 'word-1');
    expect(page.items.single.keyword, 'Dog');
    expect(page.items.single.relatedWords.single.keyword, 'Puppy');
    expect(page.items.single.createdAt, DateTime.utc(2026, 7, 17, 3, 30));
    expect(page.nextCursor, 'opaque-cursor');
    expect(page.hasMore, isTrue);
  });

  test('uses safe defaults for optional or malformed history values', () {
    final page = SnapHistoryPageResponse.fromJson({
      'items': [
        {
          'id': 'word-2',
          'keyword': 'Tree',
          'created_at': 'not-a-date',
          'related_words': 'not-a-list',
        },
      ],
    });

    final item = page.items.single;
    expect(item.snapGroupId, isNull);
    expect(item.translation, isEmpty);
    expect(item.relatedWords, isEmpty);
    expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);
  });
}
