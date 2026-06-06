import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/premium/widgets/terms_of_service_view.dart';

void main() {
  testWidgets('terms header keeps back button at screen left', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TermsOfServiceView(onBack: () {}),
      ),
    );

    final backIcon = find.byIcon(Icons.arrow_back_rounded);

    expect(backIcon, findsOneWidget);
    expect(tester.getCenter(backIcon).dx, lessThan(60));
  });
}
