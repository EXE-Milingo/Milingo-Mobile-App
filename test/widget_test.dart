import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders test host', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('MiLingo'),
        ),
      ),
    );

    expect(find.text('MiLingo'), findsOneWidget);
  });
}
