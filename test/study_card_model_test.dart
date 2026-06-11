import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';

void main() {
  test('study card keeps target language code for exam pronunciation', () {
    final card = StudyCard.fromJson({
      'card_id': 'card-1',
      'deck_id': 'deck-1',
      'deck_name': 'Daily',
      'term': 'cup',
      'translation': 'cai coc',
      'pronunciation': 'kap',
      'example_sentence': 'I drink coffee from a cup.',
      'target_lang_code': 'vi',
    });

    expect(card.targetLangCode, 'vi');
  });

  test('study card leaves target language empty when backend omits it', () {
    final card = StudyCard.fromJson({
      'card_id': 'card-1',
      'deck_id': 'deck-1',
      'deck_name': 'Daily',
      'term': 'cup',
      'translation': 'cai coc',
      'pronunciation': 'kap',
      'example_sentence': 'I drink coffee from a cup.',
    });

    expect(card.targetLangCode, isEmpty);
  });
}
