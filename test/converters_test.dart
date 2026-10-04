import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/providers/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Message to hex function should be able to generate the hex with skipping invalid characters',
      () async {
    setupLocator();
    Converters converters = Converters();
    const String message = "Hii!";
    List<String> result = await converters.messageTohex(message, false);
    List<String> expected = [
      "00c6c6c6c6fec6c6c6c600",
      "00636300e763636363f700",
      "00183c3c3c181800189800"
    ];
    expect(result, expected);
  });

  test('Converts a simple 2x2 bitmap to LED hex', () {
    List<List<int>> image = [
      [1, 0],
      [0, 1]
    ];

    List<String> result = Converters.convertBitmapToLEDHex(image, true);

    expect(result, ["1008"]);
  });

  test(
    'full-width 11x44 bitmap round-trip keeps content at the left edge (issue #1557)',
    () {
      const int badgeHeight = 11;
      const int badgeWidth = 44;

      // Full-width design: markers on both edges of the badge.
      final image = List.generate(
        badgeHeight,
        (_) => List.filled(badgeWidth, 0),
      );
      image[0][0] = 1;
      image[0][43] = 1;

      // Same path as DrawBadge save: trim=false.
      final hex = Converters.convertBitmapToLEDHex(
        image.map((row) => List<int>.from(row)).toList(),
        false,
      );
      final decoded = hexStringToBool(hex.join());

      // Protocol may pad width to a multiple of 8 (44 -> 48),
      // but must not insert left padding that shifts the design.
      expect(decoded.length, badgeHeight);
      expect(decoded[0].length % 8, 0);
      expect(decoded[0][0], isTrue); // original col 0
      expect(decoded[0][43], isTrue); // original col 43
      expect(decoded[0][2], isFalse); // must not be the shifted location
    },
  );
}
