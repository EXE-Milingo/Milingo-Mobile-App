import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/premium/providers/payment_provider.dart';

void main() {
  test('polls pending order and stops after paid result', () async {
    final order = _order();
    final gateway = _FakePaymentGateway(
      verificationResults: [
        _status('PENDING'),
        _status('PAID', isPaid: true),
      ],
    );
    var refreshCount = 0;
    final container = ProviderContainer(
      overrides: [
        paymentGatewayProvider.overrideWithValue(gateway),
        paymentPollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
        paymentEntitlementRefreshProvider.overrideWithValue(() async {
          refreshCount++;
        }),
      ],
    );
    final subscription = container.listen(
      paymentQrProvider(order),
      (_, __) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));

    final state = container.read(paymentQrProvider(order));
    expect(state.status, 'PAID');
    expect(state.isPaid, isTrue);
    expect(refreshCount, 1);
    final countAtPaid = gateway.verifyCount;

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(gateway.verifyCount, countAtPaid);

    subscription.close();
    container.dispose();
  });

  test('disposing QR provider stops pending polling', () async {
    final gateway = _FakePaymentGateway(
      verificationResults: [_status('PENDING')],
    );
    final container = ProviderContainer(
      overrides: [
        paymentGatewayProvider.overrideWithValue(gateway),
        paymentPollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
      ],
    );
    final subscription = container.listen(
      paymentQrProvider(_order()),
      (_, __) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    final countAtDispose = gateway.verifyCount;

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(gateway.verifyCount, countAtDispose);
    container.dispose();
  });

  test(
      'authenticated reconciliation recovers backend order and refreshes paid state',
      () async {
    final gateway = _FakePaymentGateway(
      pendingOrder: _order(),
      premiumStatus: const PremiumStatusResponse(isPremium: true),
    );
    var refreshCount = 0;
    final container = ProviderContainer(
      overrides: [
        paymentGatewayProvider.overrideWithValue(gateway),
        paymentUserIdProvider.overrideWithValue('firebase-user'),
        paymentEntitlementRefreshProvider.overrideWithValue(() async {
          refreshCount++;
        }),
      ],
    );
    final subscription = container.listen(
      paymentReconciliationProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      container.read(paymentReconciliationProvider).valueOrNull?.orderCode,
      123456789012,
    );
    expect(gateway.pendingCount, 1);
    expect(gateway.premiumCount, 1);
    expect(refreshCount, 1);

    subscription.close();
    container.dispose();
  });
}

class _FakePaymentGateway implements PaymentGateway {
  _FakePaymentGateway({
    this.verificationResults = const [],
    this.pendingOrder,
    this.premiumStatus = const PremiumStatusResponse(isPremium: false),
  });

  final List<PayOSOrderStatusResponse> verificationResults;
  final CreatePayOSOrderResponse? pendingOrder;
  final PremiumStatusResponse premiumStatus;
  int verifyCount = 0;
  int pendingCount = 0;
  int premiumCount = 0;

  @override
  Future<CreatePayOSOrderResponse?> getPendingOrder() async {
    pendingCount++;
    return pendingOrder;
  }

  @override
  Future<PremiumStatusResponse> getPremiumStatus() async {
    premiumCount++;
    return premiumStatus;
  }

  @override
  Future<PayOSOrderStatusResponse> verifyOrder(int orderCode) async {
    final index = verifyCount < verificationResults.length
        ? verifyCount
        : verificationResults.length - 1;
    verifyCount++;
    return verificationResults[index];
  }
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

PayOSOrderStatusResponse _status(String status, {bool isPaid = false}) =>
    PayOSOrderStatusResponse(
      orderCode: 123456789012,
      status: status,
      isPaid: isPaid,
      expiresAt: DateTime.utc(2026, 7, 15, 10, 30),
    );
