// ─────────────────────────────────────────────────────────
// Deck navigation argument (passed via GoRouter extra)
// ─────────────────────────────────────────────────────────

class DeckArg {
  const DeckArg({
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

// ─────────────────────────────────────────────────────────
// Vocabulary item displayed inside a deck
// ─────────────────────────────────────────────────────────

class VocabItem {
  const VocabItem({
    required this.word,
    required this.reading,
    required this.emoji,
    this.isNew = false,
  });

  final String word;
  final String reading;
  final String emoji;
  final bool isNew;
}
