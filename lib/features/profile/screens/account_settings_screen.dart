import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/profile/widgets/account_settings_components.dart';
import 'package:milingo/features/profile/widgets/account_settings_data.dart';

export 'package:milingo/features/profile/widgets/account_settings_data.dart';

class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Đổi tên hiển thị',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'Nhập tên hiển thị mới',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tên hiển thị không được để trống';
            }
            if (value.trim().length > 50) {
              return 'Tên hiển thị không được quá 50 ký tự';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Hủy',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6A00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Lưu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({
    required this.profile,
    this.onBack,
    super.key,
  });

  final AccountSettingsProfile profile;
  final VoidCallback? onBack;

  Future<void> _handlePasswordReset(
      BuildContext context, AccountSettingsProfile currentProfile) async {
    final email = currentProfile.email.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy địa chỉ email của tài khoản.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đổi mật khẩu?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Hệ thống sẽ gửi email hướng dẫn đặt lại mật khẩu đến:\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Gửi email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
        ),
      ),
    );

    try {
      final auth = FirebaseAuth.instance;
      await auth.setLanguageCode('vi');
      await auth.sendPasswordResetEmail(email: email);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi email đặt lại mật khẩu đến $email'),
          backgroundColor: const Color(0xFFFF6A00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi email: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _handleEditDisplayName(
    BuildContext context,
    WidgetRef ref,
    AccountSettingsProfile currentProfile,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          _EditDisplayNameDialog(initialValue: currentProfile.displayName),
    );

    if (newName == null || newName == currentProfile.displayName) return;

    if (!context.mounted) return;

    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
        ),
      ),
    );

    try {
      await ref.read(userProfileProvider.notifier).updateDisplayName(newName);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật tên hiển thị thành "$newName"'),
          backgroundColor: const Color(0xFFFF6A00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật tên hiển thị: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(userProfileProvider).valueOrNull;
    final user = FirebaseAuth.instance.currentUser;

    // Robust display name resolution to ensure it is never empty or omitted
    final asyncDisplayName = asyncProfile?.displayName.trim();
    String displayName = '';
    if (asyncDisplayName != null && asyncDisplayName.isNotEmpty) {
      displayName = asyncDisplayName;
    } else if (profile.displayName.trim().isNotEmpty) {
      displayName = profile.displayName.trim();
    } else {
      displayName = user?.displayName?.trim() ?? '';
      if (displayName.isEmpty) {
        displayName = user?.email?.split('@').first.trim() ?? 'Người dùng';
      }
    }

    // Robust email resolution
    final asyncEmail = asyncProfile?.email.trim();
    final email = (asyncEmail != null && asyncEmail.isNotEmpty)
        ? asyncEmail
        : (profile.email.trim().isNotEmpty
            ? profile.email.trim()
            : (user?.email ?? ''));

    final currentProfile = AccountSettingsProfile(
      displayName: displayName,
      email: email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: user?.phoneNumber ?? profile.phoneNumber,
      photoUrl: asyncProfile?.photoUrl ?? user?.photoURL ?? profile.photoUrl,
      localAvatarPath: asyncProfile?.localAvatarPath ?? profile.localAvatarPath,
      linkedAccounts: profile.linkedAccounts,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const AccountSettingsBackground(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: Column(
                children: [
                  AccountSettingsHeader(
                    onBack: onBack ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                  AccountAvatarSection(
                    profile: currentProfile,
                    onChangeAvatar: () {},
                  ),
                  const AccountSectionTitle('Thông tin'),
                  AccountInfoCard(
                    profile: currentProfile,
                    onTapEditDisplayName: () =>
                        _handleEditDisplayName(context, ref, currentProfile),
                  ),
                  const AccountSectionTitle('Tài khoản liên kết'),
                  AccountLinkedAccountsCard(
                      accounts: currentProfile.linkedAccounts),
                  const AccountSectionTitle('Bảo mật'),
                  AccountSecurityCard(
                    onTapChangePassword: () =>
                        _handlePasswordReset(context, currentProfile),
                  ),
                  AccountDeleteButton(onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
