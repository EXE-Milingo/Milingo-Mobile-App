const _ttsLocales = {
  'vi': 'vi-VN',
  'en': 'en-US',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'zh': 'zh-CN',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'de': 'de-DE',
  'th': 'th-TH',
  'it': 'it-IT',
};

String ttsLocaleForLanguageCode(String? languageCode) {
  final normalized = languageCode?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return 'en-US';

  final baseCode = normalized.split(RegExp('[-_]')).first;
  return _ttsLocales[normalized] ?? _ttsLocales[baseCode] ?? 'en-US';
}

String targetSpeechTextForLanguage({
  required String langCode,
  required String englishText,
  required String translatedText,
}) {
  final baseCode = langCode.trim().toLowerCase().split(RegExp('[-_]')).first;
  final primary = baseCode == 'en' ? englishText.trim() : translatedText.trim();
  if (primary.isNotEmpty) return primary;

  final fallback =
      baseCode == 'en' ? translatedText.trim() : englishText.trim();
  return fallback;
}
