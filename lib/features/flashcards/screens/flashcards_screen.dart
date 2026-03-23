import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

// ── Mock data ──────────────────────────────────────────────

class _Deck {
  const _Deck({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.total,
    required this.learned,
    required this.emoji,
  });
  final String id;
  final String name;
  final String nameVi;
  final int total;
  final int learned;
  final String emoji;
}

const _kDecks = [
  _Deck(id: 'nouns',       name: 'Nouns',      nameVi: 'Danh từ',   total: 150, learned: 15,  emoji: '📦'),
  _Deck(id: 'adjectives',  name: 'Adjectives', nameVi: 'Tính từ',   total: 48,  learned: 0,   emoji: '🎨'),
  _Deck(id: 'verbs',       name: 'Verbs',      nameVi: 'Động từ',   total: 132, learned: 59,  emoji: '⚡'),
  _Deck(id: 'pronouns',    name: 'Pronouns',   nameVi: 'Đại từ',    total: 20,  learned: 3,   emoji: '👤'),
  _Deck(id: 'adverbs',     name: 'Adverbs',    nameVi: 'Trạng từ',  total: 60,  learned: 0,   emoji: '🔤'),
  _Deck(id: 'prepositions',name: 'Prepositions',nameVi: 'Giới từ',  total: 30,  learned: 0,   emoji: '📍'),
];

// ── Screen ─────────────────────────────────────────────────

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
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
                      Expanded(child: _QuickCard(
                        icon: Icons.star_rounded,
                        iconColor: AppTheme.primaryColor,
                        iconBg: const Color(0xFFFFEDE8),
                        label: 'Yêu thích',
                        sub: '0 thẻ',
                        onTap: () => _openDeck(context, _Deck(
                          id: 'favorites', name: 'Favorites',
                          nameVi: 'Yêu thích', total: 0, learned: 0, emoji: '⭐',
                        )),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _QuickCard(
                        icon: Icons.add_rounded,
                        iconColor: AppTheme.primaryColor,
                        iconBg: const Color(0xFFFFEDE8),
                        label: 'Bộ mới',
                        sub: 'Tạo bộ thẻ',
                        onTap: () {},
                      )),
                    ],
                  ),

                  const SizedBox(height: 28),

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
                        _DeckListItem(deck: _kDecks[i], onTap: () => _openDeck(context, _kDecks[i])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _openDeck(BuildContext context, _Deck deck) {
    context.push(AppConstants.deckRoute, extra: deck);
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

  // ── Bottom nav ────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppConstants.homeRoute);
            case 1:
              context.push(AppConstants.snapAndLearnRoute);
            case 2:
              break;
            case 3:
              context.go(AppConstants.profileRoute);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: const Color(0xFFBDBDBD),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), activeIcon: Icon(Icons.camera_alt_rounded), label: 'Snap & Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.style_outlined), activeIcon: Icon(Icons.style_rounded), label: 'Flashcards'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// ── Quick-access card (Favorites / New Set) ───────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Deck list item ────────────────────────────────────────

class _DeckListItem extends StatelessWidget {
  const _DeckListItem({required this.deck, required this.onTap});
  final _Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = deck.total == 0 ? 0.0 : deck.learned / deck.total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(deck.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            // Name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        deck.nameVi,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deck.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF0F0F0),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Count + 3-dot
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${deck.learned}/${deck.total}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFFBDBDBD)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
