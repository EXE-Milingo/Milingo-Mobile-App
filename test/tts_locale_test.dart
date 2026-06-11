import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/shared/utils/tts_locale.dart';

void main() {
  test('tts locale follows normalized target language code', () {
    expect(ttsLocaleForLanguageCode('vi'), 'vi-VN');
    expect(ttsLocaleForLanguageCode('vi-VN'), 'vi-VN');
    expect(ttsLocaleForLanguageCode('it'), 'it-IT');
    expect(ttsLocaleForLanguageCode(''), 'en-US');
  });

  test('target speech text follows target language', () {
    expect(
      targetSpeechTextForLanguage(
        langCode: 'en',
        englishText: 'cup',
        translatedText: 'cai coc',
      ),
      'cup',
    );
    expect(
      targetSpeechTextForLanguage(
        langCode: 'ja',
        englishText: 'cup',
        translatedText: 'koppu',
      ),
      'koppu',
    );
  });
}
