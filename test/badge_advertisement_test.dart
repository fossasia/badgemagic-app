import 'package:badgemagic/communication/badge_advertisement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

BleDevice _device({String? name, List<String> services = const []}) =>
    BleDevice(deviceId: 'C8:17:F5:FB:BE:AB', name: name, services: services);

void main() {
  group('isBadgeAdvertisement', () {
    test('matches a device advertising the badge service', () {
      final device = _device(name: 'Anything', services: ['fee0']);

      expect(isBadgeAdvertisement(device, const []), isTrue);
    });

    test('matches a default badge name when no services were parsed', () {
      final device = _device(name: 'LSLED');

      expect(isBadgeAdvertisement(device, const []), isTrue);
    });

    test('matches a configured badge name when no services were parsed', () {
      final device = _device(name: 'My Badge');

      expect(isBadgeAdvertisement(device, const ['my badge']), isTrue);
    });

    test('rejects a known name advertising other services', () {
      final device = _device(name: 'LSLED', services: ['180d']);

      expect(isBadgeAdvertisement(device, const []), isFalse);
    });

    test('rejects an unknown device without services', () {
      final device = _device(name: 'Headphones');

      expect(isBadgeAdvertisement(device, const []), isFalse);
    });
  });
}
