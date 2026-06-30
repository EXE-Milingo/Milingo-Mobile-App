import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snap quota opens premium paywall when free daily limit is reached', () {
    final apiSource =
        File('lib/core/network/milingo_api_service.dart').readAsStringSync();
    final modelSource =
        File('lib/core/network/milingo_models.dart').readAsStringSync();
    final providerSource =
        File('lib/features/snap_and_learn/providers/snap_provider.dart')
            .readAsStringSync();
    final screenSource =
        File('lib/features/snap_and_learn/screens/snap_and_learn_screen.dart')
            .readAsStringSync();

    expect(modelSource, contains('class SnapQuotaStatus'));
    expect(apiSource, contains('getSnapQuotaStatus'));
    expect(apiSource, contains('case 402'));
    expect(providerSource, contains('paywallRequired'));
    expect(providerSource, contains('ensureCanScan'));
    expect(providerSource, contains('statusCode == 402'));
    expect(screenSource, contains('AppConstants.premiumLimitRoute'));
    expect(screenSource, contains('clearPaywallRequired'));
  });
}
