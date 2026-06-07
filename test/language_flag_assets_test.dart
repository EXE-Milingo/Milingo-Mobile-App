import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/auth/widgets/language_flag_assets.dart';

void main() {
  test('maps supported language codes to bundled flag images', () {
    expect(
      languageFlagAssetForCode('en'),
      'assets/svg/flag/US Flag.png',
    );
    expect(
      languageFlagAssetForCode('ja'),
      'assets/svg/flag/Japan Flag.png',
    );
    expect(
      languageFlagAssetForCode('zh-CN'),
      'assets/svg/flag/chinese flag.png',
    );
    expect(
      languageFlagAssetForCode('ko'),
      'assets/svg/flag/South Korea Flag.png',
    );
    expect(
      languageFlagAssetForCode('fr'),
      'assets/svg/flag/France Flag.png',
    );
    expect(
      languageFlagAssetForCode('de'),
      'assets/svg/flag/Germany Flag.png',
    );
    expect(
      languageFlagAssetForCode('es'),
      'assets/svg/flag/Spain Flag.png',
    );
    expect(
      languageFlagAssetForCode('it'),
      'assets/svg/flag/italia flag.png',
    );
    expect(languageFlagAssetForCode('vi'), isNull);
  });
}
