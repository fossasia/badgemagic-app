import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int badgeHeight = 11;
  const int badgeWidth = 44;

  List<List<bool>> emptyCanvas() => List.generate(
        badgeHeight,
        (_) => List.generate(badgeWidth, (_) => false),
      );

  List<List<bool>> processGridWithWidth(int width, {int litCol = 0}) {
    return List.generate(
      badgeHeight,
      (row) => List.generate(width, (col) => col == litCol && row == 0),
    );
  }

  group('FixedAnimation', () {
    test('renders content flush-left when narrower than the badge', () {
      final animation = FixedAnimation();
      final processGrid = processGridWithWidth(40, litCol: 0);
      final canvas = emptyCanvas();

      animation.processAnimation(
        badgeHeight,
        badgeWidth,
        0,
        processGrid,
        canvas,
      );

      // Pixel that was at column 0 must stay at column 0 (no centering).
      expect(canvas[0][0], isTrue);
      // Centered placement would have put it at column 2 for width 40.
      expect(canvas[0][2], isFalse);
      // Columns beyond the content width stay off.
      expect(canvas[0][40], isFalse);
      expect(canvas[0][43], isFalse);
    });

    test('does not clip content that is exactly badge width', () {
      final animation = FixedAnimation();
      final processGrid = processGridWithWidth(badgeWidth, litCol: 43);
      final canvas = emptyCanvas();

      animation.processAnimation(
        badgeHeight,
        badgeWidth,
        0,
        processGrid,
        canvas,
      );

      expect(canvas[0][43], isTrue);
      expect(canvas[0][0], isFalse);
    });

    test('copies leading columns when content is wider than the badge', () {
      final animation = FixedAnimation();
      final processGrid = processGridWithWidth(50, litCol: 0);
      processGrid[0][49] = true;
      final canvas = emptyCanvas();

      animation.processAnimation(
        badgeHeight,
        badgeWidth,
        0,
        processGrid,
        canvas,
      );

      expect(canvas[0][0], isTrue);
      // Columns beyond badgeWidth are not drawn onto the canvas.
      expect(canvas[0][43], isFalse);
    });

    test('clears canvas cells outside the content width', () {
      final animation = FixedAnimation();
      final processGrid = processGridWithWidth(10, litCol: 1);
      final canvas = emptyCanvas();
      // Pre-fill to ensure Fixed overwrites stale pixels.
      for (int j = 0; j < badgeWidth; j++) {
        canvas[0][j] = true;
      }

      animation.processAnimation(
        badgeHeight,
        badgeWidth,
        0,
        processGrid,
        canvas,
      );

      expect(canvas[0][1], isTrue);
      expect(canvas[0][0], isFalse);
      expect(canvas[0][10], isFalse);
      expect(canvas[0][43], isFalse);
    });
  });
}
