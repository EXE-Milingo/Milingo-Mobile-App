import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';
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
