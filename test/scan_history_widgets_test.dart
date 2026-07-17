import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/flashcards/providers/scan_history_provider.dart';
import 'package:milingo/features/flashcards/screens/scan_history_detail_screen.dart';
import 'package:milingo/features/flashcards/screens/scan_history_screen.dart';
import 'package:milingo/features/flashcards/widgets/scan_history_widgets.dart';

void main() {
  testWidgets('groups local dates and forwards item taps', (tester) async {
    final now = DateTime.now();
    final todayAtNoon = DateTime(now.year, now.month, now.day, 12);
    final yesterdayAtNoon = todayAtNoon.subtract(const Duration(days: 1));
    final items = [
      _item('today', 'Dog', 'con chó', todayAtNoon.toUtc()),
      _item('yesterday', 'Tree', 'cây', yesterdayAtNoon.toUtc()),
    ];
    String? tappedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ScanHistoryTimeline(
                items: items,
                onItemTap: (item) => tappedId = item.id,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Hôm qua'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('con chó'), findsOneWidget);

    await tester.tap(find.text('Dog'));
    expect(tappedId, 'today');
  });

  testWidgets('back buttons stay outside centered header text', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [scanHistoryUserIdProvider.overrideWithValue(null)],
        child: const MaterialApp(home: ScanHistoryScreen()),
      ),
    );
    await tester.pump();

    _expectBackButtonAtLeadingEdge(tester, 'Lịch sử quét');

    await tester.pumpWidget(
      MaterialApp(
        home: ScanHistoryDetailScreen(
          item: _item(
            'detail',
            'Dog',
            'con chó',
            DateTime.utc(2026, 7, 16),
          ),
        ),
      ),
    );

    _expectBackButtonAtLeadingEdge(tester, 'Chi tiết từ');
  });
}

void _expectBackButtonAtLeadingEdge(WidgetTester tester, String title) {
  final backButton = find.ancestor(
    of: find.byIcon(Icons.arrow_back_ios_new_rounded),
    matching: find.byType(IconButton),
  );
  final backRect = tester.getRect(backButton);
  final titleRect = tester.getRect(find.text(title));

  expect(backRect.left, closeTo(20, 0.1));
  expect(titleRect.center.dx, closeTo(195, 0.1));
}

SnapHistoryItemResponse _item(
  String id,
  String keyword,
  String translation,
  DateTime createdAt,
) {
  return SnapHistoryItemResponse(
    id: id,
    keyword: keyword,
    translation: translation,
    pronunciation: '',
    exampleSentence: '',
    createdAt: createdAt,
  );
}
