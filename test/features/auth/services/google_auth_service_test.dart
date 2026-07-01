import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:milingo/features/auth/services/google_auth_service.dart';

void main() {
  group('GoogleAuthService.mapGoogleSignInError', () {
    test('returns a setup message for missing Android web OAuth client', () {
      final message = GoogleAuthService.mapGoogleSignInError(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'serverClientId must be provided on Android',
        ),
      );

      expect(message, contains('Google Sign-In chưa được cấu hình đúng'));
      expect(message, contains('google-services.json'));
    });

    test('returns null when the user cancels Google sign in', () {
      final message = GoogleAuthService.mapGoogleSignInError(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'The user canceled sign in.',
        ),
      );

      expect(message, isNull);
    });
  });

  group('GoogleAuthService.mapUnknownSignInError', () {
    test('returns a setup message for Android developer error text', () {
      final message = GoogleAuthService.mapUnknownSignInError(
        Exception('ApiException: 10: DEVELOPER_ERROR'),
      );

      expect(message, contains('Google Sign-In chưa được cấu hình đúng'));
      expect(message, contains('SHA-1/SHA-256'));
    });
  });
}
