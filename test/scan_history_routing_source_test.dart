import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan history button pushes dedicated routes and detail stays read only',
      () {
    final constants =
        File('lib/core/constants/app_constants.dart').readAsStringSync();
    final dashboard = File(
      'lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/flashcards/screens/flashcards_screen.dart',
    ).readAsStringSync();
    final detail = File(
      'lib/features/flashcards/screens/scan_history_detail_screen.dart',
    ).readAsStringSync();

    expect(
      constants,
      contains("scanHistoryRoute = '/flashcards/scan-history'"),
    );
    expect(
      constants,
      allOf(
        contains('scanHistoryDetailRoute'),
        contains("'/flashcards/scan-history/detail'"),
      ),
    );
    expect(dashboard, contains('required this.onScanHistoryTap'));
    expect(screen, contains('context.push(AppConstants.scanHistoryRoute)'));
    expect(detail, isNot(contains('flashcardProvider')));
    expect(detail, isNot(contains('delete')));
    expect(detail, isNot(contains('favorite')));
  });
}
