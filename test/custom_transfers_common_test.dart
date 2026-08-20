import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('boolToIntBitmap', () {
    test('maps true to 1 and false to 0', () {
      final image = [
        [true, false],
        [false, true],
      ];

      expect(boolToIntBitmap(image), [
        [1, 0],
        [0, 1],
      ]);
    });
  });

  group('blankFrame', () {
    test('uses the badge dimensions by default', () {
      final frame = blankFrame();

      expect(frame.length, animationBadgeHeight);
      expect(frame.first.length, animationBadgeWidth);
      expect(frame.every((row) => row.every((cell) => cell == false)), isTrue);
    });

    test('honours custom dimensions', () {
      final frame = blankFrame(2, 3);

      expect(frame.length, 2);
      expect(frame.first.length, 3);
    });
  });

  group('frameToMessage', () {
    test('wraps a frame in a fixed-mode message with the standard flags', () {
      final frame = [
        [true, false],
        [false, true],
      ];

      final message = frameToMessage(frame);

      expect(message.mode, Mode.fixed);
      expect(message.speed, Speed.eight);
      expect(message.flash, isFalse);
      expect(message.marquee, isFalse);
      expect(
        message.text,
        Converters.convertBitmapToLEDHex(boolToIntBitmap(frame), false),
      );
    });

    test('respects a custom speed', () {
      final message = frameToMessage(blankFrame(2, 2), speed: Speed.one);

      expect(message.speed, Speed.one);
    });
  });
}
