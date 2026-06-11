const passwordResetEmailRequiredMessage =
    'Vui lòng nhập email để khôi phục mật khẩu.';
const passwordResetEmailInvalidMessage =
    'Email không hợp lệ. Vui lòng kiểm tra lại.';

final _passwordResetEmailPattern = RegExp(
  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
);

String? validatePasswordResetEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) {
    return passwordResetEmailRequiredMessage;
  }

  if (!_passwordResetEmailPattern.hasMatch(email)) {
    return passwordResetEmailInvalidMessage;
  }

  return null;
}
