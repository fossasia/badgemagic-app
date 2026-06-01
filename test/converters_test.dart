import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/providers/getitlocator.dart';
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
}
