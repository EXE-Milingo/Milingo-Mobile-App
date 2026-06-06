const _languageFlagAssets = <String, String>{
  'en': 'assets/svg/flag/US Flag.png',
  'ja': 'assets/svg/flag/Japan Flag.png',
  'zh': 'assets/svg/flag/chinese flag.png',
  'ko': 'assets/svg/flag/South Korea Flag.png',
  'fr': 'assets/svg/flag/France Flag.png',
  'de': 'assets/svg/flag/Germany Flag.png',
  'es': 'assets/svg/flag/Spain Flag.png',
  'it': 'assets/svg/flag/italia flag.png',
};

String? languageFlagAssetForCode(String code) {
  final baseCode = code.trim().toLowerCase().split(RegExp('[-_]')).first;
  return _languageFlagAssets[baseCode];
}
