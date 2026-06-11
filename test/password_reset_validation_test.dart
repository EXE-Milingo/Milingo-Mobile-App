import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/auth/utils/password_reset_validation.dart';

void main() {
  group('validatePasswordResetEmail', () {
    test('rejects empty input', () {
      expect(
        validatePasswordResetEmail(''),
        'Vui lòng nhập email để khôi phục mật khẩu.',
      );
    });

    test('rejects malformed input', () {
      expect(
        validatePasswordResetEmail('not-an-email'),
        'Email không hợp lệ. Vui lòng kiểm tra lại.',
      );
    });

    test('accepts a valid email surrounded by whitespace', () {
      expect(validatePasswordResetEmail(' user@example.com '), isNull);
    });

    test('accepts a tagged email with a multi-part domain', () {
      expect(validatePasswordResetEmail('name+tag@example.co.uk'), isNull);
    });
  });
}
