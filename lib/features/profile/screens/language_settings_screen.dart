import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/profile/widgets/language_settings_components.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  static const List<LanguageSettingsOption> _appLanguages = [
    LanguageSettingsOption(
      code: 'vi',
      label: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
    ),
    LanguageSettingsOption(
      code: 'en',
      label: 'English',
      flagAsset: 'assets/svg/flag/US Flag.png',
    ),
  ];

  static const List<LanguageSettingsOption> _learningLanguages = [
    LanguageSettingsOption(
      code: 'en',
      label: 'English',
      flagAsset: 'assets/svg/flag/US Flag.png',
    ),
    LanguageSettingsOption(
      code: 'ja',
      label: 'Tiếng Nhật',
      flagAsset: 'assets/svg/flag/Japan Flag.png',
    ),
    LanguageSettingsOption(
      code: 'zh',
      label: 'Tiếng Trung',
      flagAsset: 'assets/svg/flag/chinese flag.png',
    ),
    LanguageSettingsOption(
      code: 'de',
      label: 'Tiếng Đức',
      flagAsset: 'assets/svg/flag/Germany Flag.png',
    ),
    LanguageSettingsOption(
      code: 'it',
      label: 'Tiếng Ý',
      flagAsset: 'assets/svg/flag/italia flag.png',
    ),
    LanguageSettingsOption(
      code: 'es',
      label: 'Tiếng Tây Ban Nha',
      flagAsset: 'assets/svg/flag/Spain Flag.png',
    ),
  ];

  String _normalizeCode(String? value) {
    if (value == null) return '';
    final normalized = value.trim().toLowerCase();
    final baseCode = normalized.split(RegExp('[-_]')).first;
    return baseCode == 'jp' ? 'ja' : baseCode;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currentNative = _normalizeCode(profile?.nativeLanguage ?? 'vi');
    final currentTarget = _normalizeCode(profile?.targetLanguage ?? 'en');

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _LanguageSettingsBackground(),
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      LanguageSettingsHeader(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const LanguageSectionTitle(title: '🌐 NGÔN NGỮ ỨNG DỤNG'),
                      LanguageCardContainer(
                        children: [
                          for (var index = 0; index < _appLanguages.length; index++) ...[
                            LanguageRowItem(
                              option: _appLanguages[index],
                              isSelected: _normalizeCode(_appLanguages[index].code) == currentNative,
                              customIconAsset: 'assets/svg/globe.svg',
                              onTap: () {
                                ref.read(userProfileProvider.notifier).updateLanguages(
                                  nativeLanguage: _appLanguages[index].code,
                                );
                              },
                            ),
                            if (index != _appLanguages.length - 1)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0x0D000000),
                              ),
                          ],
                        ],
                      ),
                      const LanguageSectionTitle(title: '📚 NGÔN NGỮ ĐANG HỌC'),
                      LanguageCardContainer(
                        children: [
                          for (var index = 0; index < _learningLanguages.length; index++) ...[
                            LanguageRowItem(
                              option: _learningLanguages[index],
                              isSelected: _normalizeCode(_learningLanguages[index].code) == currentTarget,
                              onTap: () {
                                ref.read(userProfileProvider.notifier).updateLanguages(
                                  targetLanguage: _learningLanguages[index].code,
                                );
                              },
                            ),
                            if (index != _learningLanguages.length - 1)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0x0D000000),
                              ),
                          ],
                        ],
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
}

class _LanguageSettingsBackground extends StatelessWidget {
  const _LanguageSettingsBackground();

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
