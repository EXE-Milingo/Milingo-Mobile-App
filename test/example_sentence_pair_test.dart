import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

void main() {
  test('example sentence pair splits em dash joined translation', () {
    final pair = exampleSentencePairFor(
      sentence:
          'I drink coffee from a cup. \u2014 Toi uong ca phe tu mot cai coc.',
      sentenceTranslation: '',
    );

    expect(pair.original, 'I drink coffee from a cup.');
    expect(pair.translation, 'Toi uong ca phe tu mot cai coc.');
  });

  test('example sentence pair splits parenthesized translation', () {
    final pair = exampleSentencePairFor(
      sentence: 'I drink coffee from a cup. (Toi uong ca phe tu mot cai coc.)',
      sentenceTranslation: '',
    );

    expect(pair.original, 'I drink coffee from a cup.');
    expect(pair.translation, 'Toi uong ca phe tu mot cai coc.');
  });

  test('example sentence pair splits Japanese sentence with space-hyphen-space', () {
    final pair = exampleSentencePairFor(
      sentence: '犬がいます。 - Có một con chó.',
      sentenceTranslation: '',
    );

    expect(pair.original, '犬がいます。');
    expect(pair.translation, 'Có một con chó.');
  });

  test('example sentence pair splits Japanese sentence with no-space-hyphen-space', () {
    final pair = exampleSentencePairFor(
      sentence: '犬がいます。- Có một con chó.',
      sentenceTranslation: '',
    );

    expect(pair.original, '犬がいます。');
    expect(pair.translation, 'Có một con chó.');
  });
}
