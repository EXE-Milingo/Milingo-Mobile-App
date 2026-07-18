import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/snap_and_learn/widgets/vocab_bubble.dart';

void main() {
  testWidgets('related word bubble uses the enlarged footprint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VocabBubble(
              english: 'der Hund',
              translation: 'con chó',
              onSpeak: () {},
              onSave: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(VocabBubble)), const Size(112, 96));
  });

  testWidgets('related word controls dispatch independent actions', (
    tester,
  ) async {
    var speakCount = 0;
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VocabBubble(
              english: 'der Hund',
              translation: 'con chó',
              onSpeak: () => speakCount++,
              onSave: () => saveCount++,
            ),
          ),
        ),
      ),
    );

    final bubbleRect = tester.getRect(find.byType(VocabBubble));
    await tester.tapAt(bubbleRect.topCenter + const Offset(0, 18));
    await tester.pump();
    expect(speakCount, 0);
    expect(saveCount, 0);

    await tester.tap(find.byTooltip('Phát âm'));
    await tester.pump();
    expect(speakCount, 1);
    expect(saveCount, 0);

    await tester.tap(find.byTooltip('Lưu vào bộ thẻ'));
    await tester.pump();
    expect(speakCount, 1);
    expect(saveCount, 1);
  });
}
