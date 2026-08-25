import 'package:badgemagic/others/clipart_image_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trimEmptyPadding', () {
    test('removes empty left and right columns', () {
      final image = [
        [0, 1, 1, 0],
        [0, 0, 1, 0],
      ];

      expect(ClipartImageProcessor.trimEmptyPadding(image), [
        [1, 1],
        [0, 1],
      ]);
    });

    test('returns empty list when the image is all zeros', () {
      final image = [
        [0, 0],
        [0, 0],
      ];

      expect(ClipartImageProcessor.trimEmptyPadding(image), isEmpty);
    });

    test('returns empty list for an empty image', () {
      expect(ClipartImageProcessor.trimEmptyPadding([]), isEmpty);
    });
  });

  group('normalizeClipartHeight', () {
    test('returns the image unchanged when it already has 11 rows', () {
      final image = List.generate(11, (_) => [1]);

      expect(ClipartImageProcessor.normalizeClipartHeight(image), image);
    });

    test('pads a short image to 11 rows and centers the content', () {
      final image = [
        [1, 1],
      ];

      final result = ClipartImageProcessor.normalizeClipartHeight(image);

      expect(result.length, 11);
      expect(result[0], [0, 0]);
      expect(result[5], [1, 1]);
      expect(result[10], [0, 0]);
    });

    test('crops a tall image to 11 rows', () {
      final image = List.generate(13, (i) => [i]);

      final result = ClipartImageProcessor.normalizeClipartHeight(image);

      expect(result.length, 11);
      expect(result.first, [0]);
      expect(result.last, [10]);
    });
  });

  group('addClipartSideMargins', () {
    test('adds a blank column on each side', () {
      final image = [
        [1, 1],
        [2, 2],
      ];

      expect(ClipartImageProcessor.addClipartSideMargins(image), [
        [0, 1, 1, 0],
        [0, 2, 2, 0],
      ]);
    });

    test('returns the image unchanged when empty', () {
      expect(ClipartImageProcessor.addClipartSideMargins([]), isEmpty);
    });
  });
}
