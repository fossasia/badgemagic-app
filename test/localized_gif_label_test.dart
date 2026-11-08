import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:badgemagic/view/widgets/gifview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preset GIF paths map to English localization keys', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(localizedGifLabel(l10n, 'assets/gifs/bounce.gif'), 'Bounce');
    expect(localizedGifLabel(l10n, 'assets/gifs/coffee.gif'), 'Coffee');
    expect(localizedGifLabel(l10n, 'assets/gifs/wave.gif'), 'Wave');
    expect(localizedGifLabel(l10n, 'assets/gifs/missing.gif'), isEmpty);
  });
}
