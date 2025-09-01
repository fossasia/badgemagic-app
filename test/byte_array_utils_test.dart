import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ByteArrayUtils', () {
    test('toHex should convert bytes to a hexadecimal string', () {
      final bytes = [10, 20, 30, 40];
      const expectedHex = '0A141E28';

      final result = toHex(bytes);

      expect(result, equals(expectedHex));
    });

    test('isValidHex should return true for a valid hexadecimal string', () {
      const validHex = '0A141E28';

      final result = isValidHex(validHex);

      expect(result, isTrue);
    });

    test('isValidHex should return false for an invalid hexadecimal string',
        () {
      const invalidHex = 'GHIJKL';

      final result = isValidHex(invalidHex);

      expect(result, isFalse);
    });

    test(
        'hexStringToByteArray should convert a valid hexadecimal string to a byte array',
        () {
      const hexString = '0A141E28';
      final expectedBytes = [10, 20, 30, 40];

      final result = hexStringToByteArray(hexString);
      expect(result, equals(expectedBytes));
    });

    test(
        'hexStringToByteArray should throw an ArgumentError for an invalid hexadecimal string',
        () {
      const invalidHexString = 'GHIJKL';

      expect(() => hexStringToByteArray(invalidHexString), throwsArgumentError);
    });
  });
}
