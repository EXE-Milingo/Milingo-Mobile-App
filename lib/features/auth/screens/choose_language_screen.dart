import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

// ── Language data ─────────────────────────────────────────

class _Language {
  const _Language({
    required this.flag,
    required this.nameVi,
    required this.nameNative,
    required this.code,
  });
  final String flag;
  final String nameVi;
  final String nameNative;
  final String code;
}

const _kLanguages = [
  _Language(flag: '🇺🇸', nameVi: 'Tiếng Anh',        nameNative: 'English',              code: 'en'),
  _Language(flag: '🇯🇵', nameVi: 'Tiếng Nhật',        nameNative: '日本語 (Nihongo)',       code: 'ja'),
  _Language(flag: '🇰🇷', nameVi: 'Tiếng Hàn',         nameNative: '한국어 (Hangugeo)',      code: 'ko'),
  _Language(flag: '🇫🇷', nameVi: 'Tiếng Pháp',        nameNative: 'Français',              code: 'fr'),
  _Language(flag: '🇪🇸', nameVi: 'Tiếng Tây Ban Nha', nameNative: 'Español',               code: 'es'),
  _Language(flag: '🇩🇪', nameVi: 'Tiếng Đức',         nameNative: 'Deutsch',               code: 'de'),
  _Language(flag: '🇨🇳', nameVi: 'Tiếng Trung',       nameNative: '中文 (Zhōngwén)',        code: 'zh'),
];

// ── Screen ─────────────────────────────────────────────────

class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedIndex != null;

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
                      // Title
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

                      // Language cards
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kLanguages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _LanguageCard(
                          language: _kLanguages[i],
                          selected: _selectedIndex == i,
                          onTap: () =>
                              setState(() => _selectedIndex = i),
                        ),
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
                      onPressed: canContinue
                          ? () => context.go(AppConstants.homeRoute)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
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
                                  fontSize: 18, fontWeight: FontWeight.bold)),
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
}

// ── Language card ─────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _Language language;
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
            color: selected
                ? AppTheme.primaryColor
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nameVi,
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
                    language.nameNative,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),

            // Radio button
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
