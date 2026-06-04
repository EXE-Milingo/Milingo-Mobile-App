import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium terms link routes to separated terms screen', () {
    final constants =
        File('lib/core/constants/app_constants.dart').readAsStringSync();
    final router = File('lib/core/routing/app_router.dart').readAsStringSync();
    final premium = File('lib/features/premium/screens/premium_screen.dart')
        .readAsStringSync();
    final screen =
        File('lib/features/premium/screens/terms_of_service_screen.dart')
            .readAsStringSync();
    final view = File('lib/features/premium/widgets/terms_of_service_view.dart')
        .readAsStringSync();

    expect(constants, contains('termsOfServiceRoute'));
    expect(router, contains('TermsOfServiceScreen'));
    expect(premium, contains('AppConstants.termsOfServiceRoute'));
    expect(screen, contains('TermsOfServiceView'));
    expect(view, contains('Điều khoản dịch vụ'));
    expect(view, contains('Chào mừng bạn đến với nền tảng của chúng tôi'));
    expect(view, contains('Chấp nhận các điều khoản'));
  });
}
