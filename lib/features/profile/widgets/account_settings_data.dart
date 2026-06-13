class AccountSettingsProfile {
  const AccountSettingsProfile({
    required this.displayName,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber = '',
    this.photoUrl,
    this.localAvatarPath,
    this.linkedAccounts = const [],
  });

  final String displayName;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? photoUrl;
  final String? localAvatarPath;
  final List<AccountLinkedProviderData> linkedAccounts;
}

class AccountLinkedProviderData {
  const AccountLinkedProviderData({
    required this.label,
    required this.initial,
    required this.email,
    required this.isConnected,
  });

  final String label;
  final String initial;
  final String email;
  final bool isConnected;
}
