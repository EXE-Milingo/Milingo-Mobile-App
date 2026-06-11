import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/auth/utils/password_reset_validation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  bool _isSent = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    final validationMessage = validatePasswordResetEmail(email);

    if (validationMessage != null) {
      _showSnack(validationMessage, isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final auth = FirebaseAuth.instance;
      await auth.setLanguageCode('vi');
      await auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _showSentConfirmation(email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSentConfirmation(email);
      } else {
        _showSnack(_mapFirebaseError(e.code), isError: true);
      }
    } catch (_) {
      _showSnack(
        'Không thể gửi email khôi phục lúc này. Vui lòng thử lại.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSentConfirmation(String email) {
    if (!mounted) return;
    setState(() {
      _isSent = true;
      _sentEmail = email;
    });
    _showSnack(
      'Nếu email đã được đăng ký, bạn sẽ nhận được liên kết khôi phục.',
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return passwordResetEmailInvalidMessage;
      case 'missing-email':
        return passwordResetEmailRequiredMessage;
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lát rồi thử lại.';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra lại.';
      default:
        return 'Không thể gửi email khôi phục lúc này. Vui lòng thử lại.';
    }
  }

  void _goBackToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppConstants.authRoute);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.height < 680;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F0),
              Color(0xFFFFFBF4),
              Color(0xFFF4FAF4),
            ],
            stops: [0.0, 0.58, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isSmall ? 12 : 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom -
                    (isSmall ? 24 : 40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _goBackToLogin,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.textPrimary,
                      tooltip: 'Quay lại',
                    ),
                  ),
                  SizedBox(height: isSmall ? 12 : 28),
                  const _ResetHeader(),
                  SizedBox(height: isSmall ? 28 : 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isSent
                        ? _SentPanel(
                            key: const ValueKey('sent'),
                            email: _sentEmail ?? _emailController.text.trim(),
                            onResend: _isSending ? null : _sendResetEmail,
                            isSending: _isSending,
                          )
                        : _ResetForm(
                            key: const ValueKey('form'),
                            controller: _emailController,
                            isSending: _isSending,
                            onSubmit: _sendResetEmail,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _goBackToLogin,
                      child: const Text('Nhớ mật khẩu? Đăng nhập'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svg/milingo-logo.svg',
              width: 42,
              height: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Quên mật khẩu?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nhập email tài khoản MiLingo. Firebase sẽ gửi liên kết đặt lại mật khẩu cho bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ResetForm extends StatelessWidget {
  const _ResetForm({
    required this.controller,
    required this.isSending,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => isSending ? null : onSubmit(),
          decoration: const InputDecoration(
            hintText: 'name@email.com',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isSending ? null : onSubmit,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.mail_outline_rounded),
            label: Text(isSending ? 'Đang gửi...' : 'Gửi email khôi phục'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentPanel extends StatelessWidget {
  const _SentPanel({
    required this.email,
    required this.onResend,
    required this.isSending,
    super.key,
  });

  final String email;
  final VoidCallback? onResend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EFE3)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppTheme.accentColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kiểm tra hộp thư',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nếu email đã được đăng ký, Firebase sẽ gửi liên kết khôi phục '
            'tới $email. Vui lòng kiểm tra hộp thư và thư rác.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onResend,
            icon: isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(isSending ? 'Đang gửi...' : 'Gửi lại email'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: Color(0xFFFFC8B8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
