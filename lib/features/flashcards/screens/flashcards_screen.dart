import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/flashcards/widgets/vocabulary_dashboard_widgets.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  bool _showAllDecks = false;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(flashcardProvider);
    _requestCardsForReviewCount(asyncState);

    final profile = ref.watch(userProfileProvider).valueOrNull;
    final targetLang = profile?.targetLanguage ?? 'en';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: VocabularyDashboardColors.background,
        body: SafeArea(
          child: asyncState.when(
            loading: () => const VocabularyDashboardLoading(),
            error: (error, _) => VocabularyDashboardError(
              message: error.toString(),
              onRetry: () => ref.read(flashcardProvider.notifier).refresh(),
            ),
            data: (state) {
              final totalWords = _totalWords(state);
              final reviewCount = _hasLoadedReviewData(state)
                  ? _dueReviewCount(state, targetLang)
                  : null;
              final visibleDecks =
                  _showAllDecks ? state.decks : state.decks.take(4).toList();

              return Stack(
                children: [
                  const VocabularyDashboardBackground(),
                  RefreshIndicator(
                    color: VocabularyDashboardColors.accent,
                    onRefresh: () =>
                        ref.read(flashcardProvider.notifier).refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate.fixed([
                              const VocabularyDashboardHeader(
                                title: 'Từ vựng',
                              ),
                              const SizedBox(height: 16),
                              VocabularyHeroCard(totalWords: totalWords),
                              const SizedBox(height: 28),
                              VocabularyCollectionSection(
                                decks: visibleDecks,
                                showSeeAll: true,
                                onSeeAll: () => context.push(
                                  AppConstants.allCategoriesRoute,
                                ),
                                onDeckTap: (deck) => _openDeck(context, deck),
                              ),
                              const SizedBox(height: 22),
                              VocabularyReviewBanner(
                                dueCount: reviewCount,
                                onTap: () => context.push(
                                  AppConstants.examRoute,
                                  extra: const {
                                    'deckId': 'all',
                                    'deckName': 'Ôn tập hôm nay',
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      ),
    );
  }

  void _requestCardsForReviewCount(AsyncValue<FlashcardState> asyncState) {
    if (!asyncState.hasValue) return;
    final state = asyncState.value!;
    final needsLoading =
        state.decks.any((deck) => deck.total > 0 && deck.cards.isEmpty);
    if (!needsLoading) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
    });
  }

  void _openDeck(BuildContext context, DeckData deck) {
    context.push(
      AppConstants.deckRoute,
      extra: DeckArg(
        id: deck.id,
        name: deck.name,
        nameVi: deck.name,
        total: deck.total,
        learned: deck.cards.where((entry) => !entry.isNewForStudy).length,
        emoji: deck.emoji,
      ),
    );
  }
}

int _totalWords(FlashcardState state) {
  return state.decks.fold<int>(0, (total, deck) => total + deck.total);
}

bool _hasLoadedReviewData(FlashcardState state) {
  return state.decks.every((deck) => deck.total == 0 || deck.cards.isNotEmpty);
}

int _dueReviewCount(FlashcardState state, String targetLang) {
  final now = DateTime.now();
  var total = 0;
  final normalizedLang = targetLang.trim().toLowerCase();

  for (final deck in state.decks) {
    for (final entry in deck.cards) {
      if (entry.langCode.trim().toLowerCase() != normalizedLang) {
        continue;
      }

      if (entry.isNewForStudy) {
        total++;
        continue;
      }

      final nextReview = DateTime.tryParse(entry.srsNextReviewAt ?? '');
      if (nextReview != null) {
        if (!nextReview.isAfter(now)) total++;
        continue;
      }

      if (entry.isReviewing) total++;
    }
  }

  return total;
}
