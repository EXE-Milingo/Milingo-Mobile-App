import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initializeFuture;

  static const String _configurationErrorMessage =
      'Google Sign-In chưa được cấu hình đúng. Vui lòng thêm SHA-1/SHA-256 '
      'cho ứng dụng Android trong Firebase, bật Google provider, rồi tải lại '
      'google-services.json.';
  static const String _genericErrorMessage =
      'Không thể đăng nhập bằng Google. Vui lòng thử lại.';

  Future<UserCredential?> signIn() async {
    await _initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Thiết bị này chưa hỗ trợ đăng nhập Google trong ứng dụng.',
      );
    }

    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error, stackTrace) {
      _logGoogleSignInFailure(error, stackTrace);
      final message = mapGoogleSignInError(error);
      if (message == null) return null;

      throw GoogleAuthException(message);
    } on FirebaseAuthException {
      rethrow;
    } catch (error, stackTrace) {
      _logGoogleSignInFailure(error, stackTrace);
      final message = mapUnknownSignInError(error);
      if (message == null) return null;

      throw GoogleAuthException(message);
    }
  }

  Future<void> _initialize() {
    return _initializeFuture ??= _googleSignIn.initialize();
  }

  static String? mapGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return null;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _configurationErrorMessage;
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Không thể mở giao diện đăng nhập Google. Vui lòng thử lại.';
      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.userMismatch:
        break;
    }

    final details = '${error.description ?? ''} ${error.details ?? ''}';
    if (_looksLikeConfigurationError(details)) {
      return _configurationErrorMessage;
    }

    return _genericErrorMessage;
  }

  static String? mapUnknownSignInError(Object error) {
    final message = error.toString();
    if (_looksLikeConfigurationError(message)) {
      return _configurationErrorMessage;
    }
    if (_looksLikeCancellation(message)) return null;

    return _genericErrorMessage;
  }

  static bool _looksLikeConfigurationError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('developer_error') ||
        lower.contains('api exception: 10') ||
        lower.contains('apiexception: 10') ||
        lower.contains('clientconfigurationerror') ||
        lower.contains('client configuration') ||
        lower.contains('serverclientid') ||
        lower.contains('default_web_client_id') ||
        lower.contains('oauth');
  }

  static bool _looksLikeCancellation(String message) {
    final lower = message.toLowerCase();
    return lower.contains('cancel') || lower.contains('canceled');
  }

  static void _logGoogleSignInFailure(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('Google Sign-In failed: $error');
    debugPrintStack(
      label: 'Google Sign-In stack',
      stackTrace: stackTrace,
    );
  }
}
