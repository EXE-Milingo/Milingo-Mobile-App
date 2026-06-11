import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';
import 'package:milingo/features/auth/widgets/language_flag_assets.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';

class LanguageGoalScreen extends ConsumerStatefulWidget {
  const LanguageGoalScreen({super.key});

  @override
  ConsumerState<LanguageGoalScreen> createState() => _LanguageGoalScreenState();
}

class _LanguageGoalScreenState extends ConsumerState<LanguageGoalScreen> {
  late String _selectedCode;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final profile = ref.read(userProfileProvider).valueOrNull;
    _selectedCode = _normalizeLanguageCode(profile?.targetLanguage);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(userStatsValueProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final languageOptions = _languageOptionsFor(supportedLanguages.valueOrNull);
    final language = _languageByCode(_selectedCode, languageOptions);
    final vocabularyCount = _formatVocabularyCount(stats.totalPoints);
    final wordGoal = _weeklyWordGoal(stats);
    final scanGoal = _weeklyScanGoal(stats);

    return Scaffold(
      backgroundColor: _LanguageGoalColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),
              const Text(
                'Ngôn ngữ muốn học',
                style: TextStyle(
                  color: _LanguageGoalColors.primary,
                  fontSize: 30,
                  height: 36 / 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thay đổi ngôn ngữ khác',
                style: TextStyle(
                  color: _LanguageGoalColors.mutedText,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 32),
              _ActiveLanguageCard(
                language: language,
                vocabularyCount: vocabularyCount,
              ),
              const SizedBox(height: 32),
              _LanguageSelector(
                languages: languageOptions,
                selectedCode: _selectedCode,
                onChanged: _changeLanguage,
              ),
              const SizedBox(height: 36),
              const Text(
                'Mục tiêu tuần này',
                style: TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              _WeeklyGoalCard(goal: wordGoal),
              const SizedBox(height: 16),
              _WeeklyGoalCard(goal: scanGoal),
              const SizedBox(height: 98),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 158,
                  height: 56,
                  child: FilledButton(
                    onPressed: _saveLanguage,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _LanguageGoalColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    child: const Text('Lưu thay đổi'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLanguage() async {
    await ref
        .read(userProfileProvider.notifier)
        .updateLanguages(targetLanguage: _selectedCode);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _changeLanguage(String code) async {
    setState(() => _selectedCode = code);

    await ref
        .read(userProfileProvider.notifier)
        .updateLanguages(targetLanguage: code);
  }

  static String _normalizeLanguageCode(String? value) {
    return _canonicalLanguageCode(value);
  }

  static _LanguageOption _languageByCode(
    String code,
    List<_LanguageOption> languages,
  ) {
    final selectedKey = _languageCodeKey(code);
    return languages.firstWhere(
      (language) => _languageCodeKey(language.code) == selectedKey,
      orElse: () => languages.firstWhere(
        (language) => _languageCodeKey(language.code) == 'en',
        orElse: () => languages.first,
      ),
    );
  }

  static String _formatVocabularyCount(int value) {
    if (value >= 1000) {
      final k = value / 1000;
      final formatted =
          k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1);
      return '${formatted}k';
    }
    return value.toString();
  }

  static _WeeklyGoal _weeklyWordGoal(UserStatsResponse stats) {
    final completed = stats.totalPoints.clamp(0, 50);
    return _WeeklyGoal(
      title: 'Học 50 từ mới',
      progressLabel: '$completed / 50 từ',
      progress: completed / 50,
      iconPath: 'assets/svg/language-speaker.svg',
      iconBackground: const Color(0xFFFFD8CB),
      progressColor: _LanguageGoalColors.primary,
      completed: completed >= 50,
    );
  }

  static _WeeklyGoal _weeklyScanGoal(UserStatsResponse stats) {
    final completed = stats.coins.clamp(0, 3);
    return _WeeklyGoal(
      title: 'Hoàn thành 3 AR scans',
      progressLabel: '$completed / 3 scans',
      progress: completed / 3,
      iconPath: 'assets/svg/language-scan.svg',
      iconBackground: const Color(0xFFDDF1FF),
      progressColor: const Color(0xFF0D7DC2),
      completed: completed >= 3,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          icon: const _LanguageSvgIcon(
            'assets/svg/account-back.svg',
            width: 16,
            height: 16,
            color: _LanguageGoalColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _ActiveLanguageCard extends StatelessWidget {
  const _ActiveLanguageCard({
    required this.language,
    required this.vocabularyCount,
  });

  final _LanguageOption language;
  final String vocabularyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18B46B50),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: _GlowCircle(
              size: 120,
              color: Colors.white.withValues(alpha: 0.36),
            ),
          ),
          Positioned(
            left: -42,
            bottom: -26,
            child: _GlowCircle(
              size: 140,
              color: const Color(0xFFE6F7FF).withValues(alpha: 0.72),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                language.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 42),
              Center(
                child: _FlagImage(
                  assetPath: language.flagPath,
                  fallbackText: language.flagText,
                  size: 160,
                  borderWidth: 10,
                ),
              ),
              const Spacer(),
              Text(
                vocabularyCount,
                style: const TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 24,
                  height: 28 / 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const Text(
                'Từ vựng',
                style: TextStyle(
                  color: _LanguageGoalColors.mutedText,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.languages,
    required this.selectedCode,
    required this.onChanged,
  });

  final List<_LanguageOption> languages;
  final String selectedCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ngôn ngữ mục tiêu',
                style: TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _LanguageGoalColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(72, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.9,
                ),
              ),
              child: const Text('THÊM MỚI'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final language in languages) ...[
                _LanguagePill(
                  language: language,
                  selected: _languageCodeKey(language.code) ==
                      _languageCodeKey(selectedCode),
                  onTap: () => onChanged(language.code),
                ),
                const SizedBox(width: 16),
              ],
              const _AddLanguagePill(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            _FlagImage(
              assetPath: language.flagPath,
              fallbackText: language.flagText,
              size: 58,
              borderWidth: selected ? 4 : 2,
              borderColor: selected
                  ? _LanguageGoalColors.primary
                  : const Color(0xFFE9BFB1),
            ),
            const SizedBox(height: 8),
            Text(
              selected ? language.selectedLabel : language.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? _LanguageGoalColors.primary
                    : _LanguageGoalColors.text,
                fontSize: 12,
                height: 14 / 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLanguagePill extends StatelessWidget {
  const _AddLanguagePill();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD6A89A),
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(
                  color: Color(0xFF9E756B),
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LanguageGoalColors.mutedText,
              fontSize: 12,
              height: 14 / 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.goal});

  final _WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D9D604A),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: goal.iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _LanguageSvgIcon(goal.iconPath, width: 22, height: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _LanguageGoalColors.text,
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GoalSwitch(done: goal.completed),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  goal.progressLabel,
                  style: const TextStyle(
                    color: _LanguageGoalColors.mutedText,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goal.progress.clamp(0, 1).toDouble(),
                      backgroundColor: const Color(0xFFFFDCD4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.progressColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSwitch extends StatelessWidget {
  const _GoalSwitch({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF2E73FF) : const Color(0xFFFFDAD2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: done ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Center(
                  child: _LanguageSvgIcon(
                    'assets/svg/language-check.svg',
                    width: 12,
                    height: 12,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _FlagImage extends StatelessWidget {
  const _FlagImage({
    required this.size,
    required this.borderWidth,
    this.assetPath,
    this.fallbackText,
    this.borderColor = _LanguageGoalColors.primary,
  });

  final String? assetPath;
  final String? fallbackText;
  final double size;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: assetPath == null
            ? _FlagFallback(text: fallbackText, size: size)
            : Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _FlagFallback(text: fallbackText, size: size);
                },
              ),
      ),
    );
  }
}

class _FlagFallback extends StatelessWidget {
  const _FlagFallback({required this.text, required this.size});

  final String? text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF4EF),
      child: Center(
        child: Text(
          text?.trim().isNotEmpty == true ? text! : '🌐',
          style: TextStyle(fontSize: size * 0.42, height: 1),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LanguageSvgIcon extends StatelessWidget {
  const _LanguageSvgIcon(
    this.assetPath, {
    required this.width,
    required this.height,
    this.color,
  });

  final String assetPath;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.title,
    required this.label,
    required this.selectedLabel,
    this.flagPath,
    this.flagText,
  });

  factory _LanguageOption.fromSupportedLanguage(SupportedLanguage language) {
    final code = _canonicalLanguageCode(language.code);
    final codeKey = _languageCodeKey(code);
    final label = _languageLabels[codeKey] ?? codeKey.toUpperCase();

    return _LanguageOption(
      code: code,
      title: _languageTitles[codeKey] ?? language.name,
      label: label,
      selectedLabel: '$label (Đang học)',
      flagPath:
          _legacyFlagPathForCode(codeKey) ?? languageFlagAssetForCode(code),
      flagText: language.flag,
    );
  }

  final String code;
  final String title;
  final String label;
  final String selectedLabel;
  final String? flagPath;
  final String? flagText;
}

class _WeeklyGoal {
  const _WeeklyGoal({
    required this.title,
    required this.progressLabel,
    required this.progress,
    required this.iconPath,
    required this.iconBackground,
    required this.progressColor,
    required this.completed,
  });

  final String title;
  final String progressLabel;
  final double progress;
  final String iconPath;
  final Color iconBackground;
  final Color progressColor;
  final bool completed;
}

List<_LanguageOption> _languageOptionsFor(List<SupportedLanguage>? languages) {
  if (languages == null || languages.isEmpty) return _fallbackLanguageOptions;

  final options = languages
      .where((language) => language.code.trim().isNotEmpty)
      .map(_LanguageOption.fromSupportedLanguage)
      .toList(growable: false);

  return options.isEmpty ? _fallbackLanguageOptions : options;
}

String _canonicalLanguageCode(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return 'en';

  return normalized.toLowerCase() == 'jp' ? 'ja' : normalized;
}

String _languageCodeKey(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'en';

  final baseCode = normalized.split(RegExp('[-_]')).first;
  return baseCode == 'jp' ? 'ja' : baseCode;
}

String? _legacyFlagPathForCode(String codeKey) {
  return switch (codeKey) {
    'en' => 'assets/images/uk.png',
    'fr' => 'assets/images/france.png',
    'ja' => 'assets/images/jp.png',
    _ => null,
  };
}

const _languageTitles = <String, String>{
  'en': 'Tiếng Anh',
  'ja': 'Tiếng Nhật',
  'ko': 'Tiếng Hàn',
  'fr': 'Tiếng Pháp',
  'es': 'Tiếng Tây Ban Nha',
  'de': 'Tiếng Đức',
  'zh': 'Tiếng Trung',
  'it': 'Tiếng Ý',
};

const _languageLabels = <String, String>{
  'en': 'ANH',
  'ja': 'NHẬT',
  'ko': 'HÀN',
  'fr': 'PHÁP',
  'es': 'TBN',
  'de': 'ĐỨC',
  'zh': 'TRUNG',
  'it': 'Ý',
};

const _fallbackLanguageOptions = [
  _LanguageOption(
    code: 'fr',
    title: 'Tiếng Pháp',
    label: 'PHÁP',
    selectedLabel: 'PHÁP (Đang học)',
    flagPath: 'assets/images/france.png',
  ),
  _LanguageOption(
    code: 'en',
    title: 'Tiếng Anh',
    label: 'ANH',
    selectedLabel: 'ANH (Đang học)',
    flagPath: 'assets/images/uk.png',
  ),
  _LanguageOption(
    code: 'ja',
    title: 'Tiếng Nhật',
    label: 'NHẬT',
    selectedLabel: 'NHẬT (Đang học)',
    flagPath: 'assets/images/jp.png',
  ),
  _LanguageOption(
    code: 'ko',
    title: 'Tiếng Hàn',
    label: 'HÀN',
    selectedLabel: 'HÀN (Đang học)',
    flagPath: 'assets/svg/flag/South Korea Flag.png',
  ),
  _LanguageOption(
    code: 'es',
    title: 'Tiếng Tây Ban Nha',
    label: 'TBN',
    selectedLabel: 'TBN (Đang học)',
    flagPath: 'assets/svg/flag/Spain Flag.png',
  ),
  _LanguageOption(
    code: 'de',
    title: 'Tiếng Đức',
    label: 'ĐỨC',
    selectedLabel: 'ĐỨC (Đang học)',
    flagPath: 'assets/svg/flag/Germany Flag.png',
  ),
  _LanguageOption(
    code: 'zh',
    title: 'Tiếng Trung',
    label: 'TRUNG',
    selectedLabel: 'TRUNG (Đang học)',
    flagPath: 'assets/svg/flag/chinese flag.png',
  ),
  _LanguageOption(
    code: 'it',
    title: 'Tiếng Ý',
    label: 'Ý',
    selectedLabel: 'Ý (Đang học)',
    flagPath: 'assets/svg/flag/italia flag.png',
  ),
];

class _LanguageGoalColors {
  static const background = Color(0xFFFFF1EC);
  static const primary = Color(0xFFE4502E);
  static const primaryDark = Color(0xFFC94A24);
  static const text = Color(0xFF2A1D19);
  static const mutedText = Color(0xFF765753);
}
