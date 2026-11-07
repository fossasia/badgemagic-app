import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updateLocale switches USB strings from English to Russian', () async {
    final service = LocalizationService();
    await service.init(const Locale('en'));
    expect(service.l10n.searchingUsbBadge, 'Searching for USB badge...');

    await service.updateLocale(const Locale('ru'));
    expect(service.l10n.searchingUsbBadge, 'Поиск USB-бейджа...');
    expect(service.l10n.firmwareUpdate, 'Обновление прошивки');
  });
}
