import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';
import 'package:milingo/features/auth/widgets/language_flag_assets.dart';

// ── Screen ─────────────────────────────────────────────────

class ChooseLanguageScreen extends ConsumerStatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  ConsumerState<ChooseLanguageScreen> createState() =>
      _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends ConsumerState<ChooseLanguageScreen> {
  int? _selectedIndex;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(supportedLanguagesProvider);
    final canContinue = _selectedIndex != null && !_isSaving;

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
              Color(0xFFFCEDE8),
              Color(0xFFFFF8F4),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF424242)),
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppConstants.registerRoute),
                      ),
                    ),
                    const Text(
                      'MILINGO AI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF424242),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bạn muốn học ngôn ngữ nào?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chọn ngôn ngữ mục tiêu để bắt đầu hành trình.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9E9E),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Language list (driven by backend) ──
                      languagesAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) {
                          // Fallback to hardcoded list on network error
                          return _buildLanguageList(_fallbackLanguages);
                        },
                        data: (languages) {
                          final list = languages.isEmpty
                              ? _fallbackLanguages
                              : languages;
                          return _buildLanguageList(list);
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Continue button ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: canContinue ? 1.0 : 0.45,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canContinue ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tiếp tục',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('→',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageList(List<SupportedLanguage> languages) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: languages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _LanguageCard(
        language: languages[i],
        selected: _selectedIndex == i,
        onTap: () => setState(() => _selectedIndex = i),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_selectedIndex == null) return;

    final languages =
        ref.read(supportedLanguagesProvider).valueOrNull ?? _fallbackLanguages;
    final selected = languages[_selectedIndex!];

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final displayName =
          user?.displayName ?? user?.email?.split('@').first ?? 'Milingo User';

      await ref.read(authServiceProvider).initProfile(
            displayName: displayName,
            targetLanguage: selected.code,
          );
    } catch (_) {
      // initProfile failure is non-blocking — backend is idempotent.
      // We still proceed to the main app.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) context.go(AppConstants.snapAndLearnRoute);
  }
}

// ── Fallback hardcoded languages (offline safety net) ───

const _fallbackLanguages = [
  SupportedLanguage(
      code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
  SupportedLanguage(
      code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
  SupportedLanguage(
      code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  SupportedLanguage(
      code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  SupportedLanguage(
      code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  SupportedLanguage(
      code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
  SupportedLanguage(
      code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  SupportedLanguage(
      code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
];

// ── Language card widget ──────────────────────────────────

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final SupportedLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F0EC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _LanguageFlag(language: language),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    language.nativeName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryColor
                      : const Color(0xFFD0D0D0),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check_rounded,
                          color: Colors.white, size: 13),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.language});

  final SupportedLanguage language;

  @override
  Widget build(BuildContext context) {
    final assetPath = languageFlagAssetForCode(language.code);
    if (assetPath == null) {
      return Text(language.flag, style: const TextStyle(fontSize: 28));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        assetPath,
        width: 34,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Text(language.flag, style: const TextStyle(fontSize: 28));
        },
      ),
    );
  }
}
