import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/premium/widgets/payment_qr_view.dart';

void main() {
  testWidgets('shows native QR and copy/save transfer details', (tester) async {
    final copiedValues = <String>[];
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentQrView(
          order: _order(),
          status: 'PENDING',
          isChecking: false,
          qrBoundaryKey: GlobalKey(),
          onClose: () {},
          onCopy: (value) => copiedValues.add(value),
          onSaveQr: () async => saved = true,
          onRetry: () {},
          onCreateNewOrder: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('payos-qr-code')), findsOneWidget);
    expect(
      find.text('Ngân hàng Thương mại Cổ phần Quân đội (MB)'),
      findsOneWidget,
    );
    expect(find.text('VietQR • Chuyển nhanh NAPAS 247'), findsOneWidget);

    final boundaryCenter = tester.getCenter(
      find.byKey(const Key('payment-qr-boundary')),
    );
    final qrCenter = tester.getCenter(
      find.byKey(const Key('payos-qr-code')),
    );
    expect(qrCenter.dx, closeTo(boundaryCenter.dx, 0.1));
    expect(find.text('139.000 ₫'), findsOneWidget);
    expect(find.text('MERCHANT NAME'), findsOneWidget);
    expect(find.text('113366668888'), findsOneWidget);
    expect(find.text('Milingo pro'), findsOneWidget);
    expect(find.text('Lưu mã QR'), findsOneWidget);

    final copyAccount = find.byKey(const Key('copy-account-number'));
    await tester.ensureVisible(copyAccount);
    await tester.tap(copyAccount);
    await tester.pump();
    expect(copiedValues, contains('113366668888'));

    final saveQr = find.text('Lưu mã QR');
    await tester.ensureVisible(saveQr);
    await tester.tap(saveQr);
    await tester.pump();
    expect(saved, isTrue);
  });

  testWidgets('expired QR offers creation of a new order', (tester) async {
    var createNew = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentQrView(
          order: _order(),
          status: 'EXPIRED',
          isChecking: false,
          qrBoundaryKey: GlobalKey(),
          onClose: () {},
          onCopy: (_) {},
          onSaveQr: () async {},
          onRetry: () {},
          onCreateNewOrder: () => createNew = true,
        ),
      ),
    );

    expect(find.text('Mã QR đã hết hạn'), findsOneWidget);
    final createNewButton = find.text('Tạo mã QR mới');
    await tester.ensureVisible(createNewButton);
    await tester.tap(createNewButton);
    await tester.pump();
    expect(createNew, isTrue);
  });
}

CreatePayOSOrderResponse _order() => CreatePayOSOrderResponse(
      bin: '970422',
      bankName: 'Ngân hàng Thương mại Cổ phần Quân đội (MB)',
      accountNumber: '113366668888',
      accountName: 'MERCHANT NAME',
      amount: 139000,
      description: 'Milingo pro',
      checkoutUrl: '',
      orderCode: 123456789012,
      paymentLinkId: 'payment-link-id',
      qrCode: '00020101021238570010A000000727',
      status: 'PENDING',
      expiresAt: DateTime.utc(2026, 7, 15, 10, 30),
    );
