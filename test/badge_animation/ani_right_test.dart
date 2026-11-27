import 'package:badgemagic/badge_animation/ani_right.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<bool>> freshCanvas(int height, int width) =>
    List.generate(height, (_) => List.generate(width, (_) => false));

bool isFullyBlank(List<List<bool>> canvas) =>
    canvas.every((row) => row.every((cell) => !cell));

void main() {
  group('RightAnimation', () {
    const content = [
      [true, false, true, false, true, false],
      [false, true, false, true, false, true],
    ];
    const badgeHeight = 2;
    const badgeWidth = 4;

    List<List<bool>> render(int animationIndex) {
      final canvas = freshCanvas(badgeHeight, badgeWidth);
      RightAnimation().processAnimation(
          badgeHeight, badgeWidth, animationIndex, content, canvas);
      return canvas;
    }

    test('no frame in a full cycle is fully blank', () {
      for (var k = 0; k < content[0].length; k++) {
        expect(isFullyBlank(render(k)), isFalse,
            reason: 'frame $k is fully blank');
      }
    });

    test('consecutive frames shift by exactly one column', () {
      final contentWidth = content[0].length;
      for (var k = 0; k < contentWidth - 1; k++) {
        final wide = freshCanvas(badgeHeight, badgeWidth + 1);
        RightAnimation()
            .processAnimation(badgeHeight, badgeWidth + 1, k, content, wide);
        final expected = <List<bool>>[];
        for (var i = 0; i < badgeHeight; i++) {
          expected.add([
            content[i][(contentWidth - k - 1) % contentWidth],
            ...wide[i].sublist(0, badgeWidth - 1),
          ]);
        }
        expect(render(k + 1), equals(expected));
      }
    });

    test('frame sequence repeats with period newWidth', () {
      const narrow = [
        [true, false, true]
      ];
      List<List<bool>> frameAt(int animationIndex) {
        final canvas = freshCanvas(1, 4);
        RightAnimation().processAnimation(1, 4, animationIndex, narrow, canvas);
        return canvas;
      }

      expect(
          frameAt(0),
          equals([
            [true, false, true, true]
          ]));
      expect(
          frameAt(1),
          equals([
            [true, true, false, true]
          ]));
      expect(
          frameAt(2),
          equals([
            [false, true, true, false]
          ]));
      for (var k = 0; k < 3; k++) {
        expect(frameAt(k + 3), equals(frameAt(k)));
      }
    });

    test('narrow content tiles without blanks', () {
      const narrow = [
        [true, false]
      ];
      List<List<bool>> frameAt(int animationIndex) {
        final canvas = freshCanvas(1, 6);
        RightAnimation().processAnimation(1, 6, animationIndex, narrow, canvas);
        return canvas;
      }

      expect(
          frameAt(0),
          equals([
            [true, false, true, false, true, false]
          ]));
      expect(
          frameAt(1),
          equals([
            [false, true, false, true, false, true]
          ]));
      expect(isFullyBlank(frameAt(0)), isFalse);
      expect(isFullyBlank(frameAt(1)), isFalse);
    });

    test('empty grid does not crash and leaves the canvas blank', () {
      final canvas = freshCanvas(1, 4);
      RightAnimation().processAnimation(1, 4, 0, <List<bool>>[], canvas);
      expect(isFullyBlank(canvas), isTrue);

      final emptyRowCanvas = freshCanvas(1, 4);
      RightAnimation().processAnimation(1, 4, 0, [<bool>[]], emptyRowCanvas);
      expect(isFullyBlank(emptyRowCanvas), isTrue);
    });
  });
}
