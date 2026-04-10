import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/screens/exam_screen.dart' show ExamScreen;
import 'package:milingo/features/flashcards/widgets/deck_list_item.dart';
import 'package:milingo/features/flashcards/widgets/exam_banner.dart';
import 'package:milingo/features/flashcards/widgets/quick_card.dart';
import 'package:milingo/shared/widgets/floating_nav_button.dart';

// ── Mock data ──────────────────────────────────────────────

const _kDecks = [
  DeckArg(id: 'nouns',        name: 'Nouns',        nameVi: 'Danh từ',  total: 150, learned: 15, emoji: '📦'),
  DeckArg(id: 'adjectives',   name: 'Adjectives',   nameVi: 'Tính từ',  total: 48,  learned: 0,  emoji: '🎨'),
  DeckArg(id: 'verbs',        name: 'Verbs',        nameVi: 'Động từ',  total: 132, learned: 59, emoji: '⚡'),
  DeckArg(id: 'pronouns',     name: 'Pronouns',     nameVi: 'Đại từ',   total: 20,  learned: 3,  emoji: '👤'),
  DeckArg(id: 'adverbs',      name: 'Adverbs',      nameVi: 'Trạng từ', total: 60,  learned: 0,  emoji: '🔤'),
  DeckArg(id: 'prepositions', name: 'Prepositions', nameVi: 'Giới từ',  total: 30,  learned: 0,  emoji: '📍'),
];

// ── Screen ─────────────────────────────────────────────────

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick-access cards row
                      Row(
                        children: [
                          Expanded(child: QuickCard(
                            icon: Icons.star_rounded,
                            iconColor: AppTheme.primaryColor,
                            iconBg: const Color(0xFFFFEDE8),
                            label: 'Yêu thích',
                            sub: '0 thẻ',
                            onTap: () => _openDeck(context, const DeckArg(
                              id: 'favorites', name: 'Favorites',
                              nameVi: 'Yêu thích', total: 0, learned: 0, emoji: '⭐',
                            )),
                          )),
                          const SizedBox(width: 14),
                          Expanded(child: QuickCard(
                            icon: Icons.add_rounded,
                            iconColor: AppTheme.primaryColor,
                            iconBg: const Color(0xFFFFEDE8),
                            label: 'Bộ mới',
                            sub: 'Tạo bộ thẻ',
                            onTap: () {},
                          )),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Exam entry banner ──────────────────
                      ExamBanner(onTap: () => _openExam(context)),

                      const SizedBox(height: 20),

                      Text(
                        'Danh mục',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Deck list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kDecks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            DeckListItem.fromArg(_kDecks[i], onTap: () => _openDeck(context, _kDecks[i])),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Floating Navigation Button ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: const FloatingNavButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      right: 16,
      child: const FloatingNavButton(),
    );
  }

  void _openDeck(BuildContext context, DeckArg deck) {
    context.push(AppConstants.deckRoute, extra: deck);
  }

  void _openExam(BuildContext context) {
    _showLanguagePicker(context);
  }

  void _showLanguagePicker(BuildContext context) {
    const langs = [
      ('🇺🇸', 'Tiếng Anh',        'en'),
      ('🇯🇵', 'Tiếng Nhật',        'ja'),
      ('🇰🇷', 'Tiếng Hàn',         'ko'),
      ('🇫🇷', 'Tiếng Pháp',        'fr'),
      ('🇪🇸', 'Tiếng Tây Ban Nha', 'es'),
      ('🇩🇪', 'Tiếng Đức',         'de'),
      ('🇨🇳', 'Tiếng Trung',       'zh'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Chọn ngôn ngữ kiểm tra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...langs.map((l) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(l.$1, style: const TextStyle(fontSize: 24))),
              ),
              title: Text(l.$2,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppTheme.primaryColor),
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                  AppConstants.examRoute,
                  extra: {'langCode': l.$3, 'langName': l.$2},
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  // ── Gradient header ────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            const Color(0xFFD94E28),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  // Language chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Text('🇬🇧', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          'English',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Flashcards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chọn bộ thẻ để luyện tập',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav (removed – using FloatingNavButton instead) ──
  // kept as a stub to avoid removing the helper entirely
  Widget _buildBottomNavStub(BuildContext context) => const SizedBox.shrink();
}

