import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/profile/screens/account_settings_screen.dart';
import 'package:milingo/features/profile/screens/language_settings_screen.dart';
import 'package:milingo/features/profile/widgets/profile_header_section.dart';
import 'package:milingo/features/profile/widgets/profile_premium_card.dart';
import 'package:milingo/features/profile/widgets/profile_settings_section.dart';
import 'package:milingo/features/profile/widgets/profile_stats_section.dart';
import 'package:milingo/features/profile/widgets/profile_view_data.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';
import 'package:milingo/features/premium/providers/subscription_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(userStatsValueProvider);
    final flashcards = ref.watch(flashcardStateProvider);
    final wordsLearned =
        flashcards.decks.fold<int>(0, (sum, deck) => sum + deck.total);

    final isPremium = profile?.isPremium ?? false;
    final subscriptionAsync =
        isPremium ? ref.watch(subscriptionOverviewProvider) : null;
    final subscription = subscriptionAsync?.valueOrNull;

    final data = ProfileViewData(
      displayName: _displayNameFor(user, profile),
      email: _emailFor(user, profile),
      memberSince: _memberSinceLabel(user),
      isPremium: isPremium,
      currentStreak: stats.currentStreak,
      coins: stats.coins,
      totalPoints: stats.totalPoints,
      wordsLearned: wordsLearned,
      photoUrl: profile?.photoUrl ?? user?.photoURL,
      localAvatarPath: profile?.localAvatarPath,
      premiumPlanName: subscription?.planName,
      premiumExpiresAt: subscription?.expiresAt,
    );

    return Scaffold(
      backgroundColor: _ProfileColors.background,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _ProfileBackground(),
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                  sliver: SliverList.list(
                    children: [
                      ProfileHeaderSection(data: data),
                      const SizedBox(height: 20),
                      ProfilePremiumCard(
                        data: data,
                        onUpgradeTap: () {
                          if (data.isPremium) {
                            context.push(AppConstants.subscriptionRoute);
                          } else {
                            context.push(AppConstants.premiumRoute);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ProfileStatsSection(data: data),
                      const SizedBox(height: 28),
                      ProfileSettingsSection(
                        items: _settingsItems(context, user, profile),
                        onLogoutTap: () => _logout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<ProfileSettingsItemData> _settingsItems(
    BuildContext context,
    User? user,
    UserProfileResponse? profile,
  ) {
    return [
      ProfileSettingsItemData(
        label: 'Tài khoản',
        assetPath: 'assets/svg/new-profile/profile-account.svg',
        onTap: () => _openAccountSettings(context, user, profile),
      ),
      ProfileSettingsItemData(
        label: 'Gói Premium',
        assetPath: 'assets/svg/new-profile/premium.svg',
        onTap: () => context.push(AppConstants.subscriptionRoute),
      ),
      ProfileSettingsItemData(
        label: 'Ngôn ngữ',
        assetPath: 'assets/svg/new-profile/language.svg',
        onTap: () => _openLanguageSettings(context),
      ),
      ProfileSettingsItemData(
        label: 'Hỗ trợ',
        assetPath: 'assets/svg/new-profile/support.svg',
        onTap: () => context.push(AppConstants.supportRoute),
      ),
      ProfileSettingsItemData(
        label: 'About',
        assetPath: 'assets/svg/new-profile/about.svg',
        onTap: () => context.push(AppConstants.aboutRoute),
      ),
    ];
  }

  static String _displayNameFor(User? user, UserProfileResponse? profile) {
    final profileName = profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final firebaseName = user?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;

    final emailName = user?.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) return emailName;

    return 'Milingo';
  }

  static String _emailFor(User? user, UserProfileResponse? profile) {
    final profileEmail = profile?.email.trim();
    if (profileEmail != null && profileEmail.isNotEmpty) return profileEmail;
    return user?.email ?? '';
  }

  static String _memberSinceLabel(User? user) {
    final year = user?.metadata.creationTime?.year;
    if (year == null) return '';
    return 'Thành viên từ $year';
  }

  static void _openAccountSettings(
    BuildContext context,
    User? user,
    UserProfileResponse? profile,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AccountSettingsScreen(profile: _accountProfile(user, profile)),
      ),
    );
  }

  static void _openLanguageSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LanguageSettingsScreen(),
      ),
    );
  }

  static AccountSettingsProfile _accountProfile(
    User? user,
    UserProfileResponse? profile,
  ) {
    final name = _displayNameFor(user, profile);
    final parts = name.split(RegExp(r'\s+'));

    return AccountSettingsProfile(
      displayName: name,
      email: _emailFor(user, profile),
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      phoneNumber: user?.phoneNumber ?? '',
      photoUrl: profile?.photoUrl ?? user?.photoURL,
      localAvatarPath: profile?.localAvatarPath,
      linkedAccounts: _linkedAccountsFor(user),
    );
  }

  static List<AccountLinkedProviderData> _linkedAccountsFor(User? user) {
    final providers = user?.providerData ?? const <UserInfo>[];
    return [
      _linkedAccountFor(providers, 'google.com', 'Google', 'G'),
      _linkedAccountFor(providers, 'apple.com', 'Apple', 'A'),
      _linkedAccountFor(providers, 'facebook.com', 'Facebook', 'F'),
    ];
  }

  static AccountLinkedProviderData _linkedAccountFor(
    List<UserInfo> providers,
    String providerId,
    String label,
    String initial,
  ) {
    UserInfo? matched;
    for (final provider in providers) {
      if (provider.providerId == providerId) {
        matched = provider;
        break;
      }
    }

    return AccountLinkedProviderData(
      label: label,
      initial: initial,
      email: matched?.email ?? '',
      isConnected: matched != null,
    );
  }

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await FirebaseAuth.instance.signOut();
    ref.invalidate(userProfileProvider);
    ref.invalidate(userStatsProvider);
    ref.invalidate(flashcardProvider);
    if (context.mounted) context.go(AppConstants.authRoute);
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: _Glow(size: 320, color: Color(0x38FF8A1F)),
        ),
        Positioned(
          top: 320,
          left: -96,
          child: _Glow(size: 256, color: Color(0x1AFF4D1A)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _ProfileColors {
  static const background = Color(0xFFFBF7F2);
}
