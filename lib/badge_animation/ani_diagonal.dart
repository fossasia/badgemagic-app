import 'package:badgemagic/badge_animation/animation_abstract.dart';

class DiagonalAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int vHeight = badgeWidth ~/ 3 + 1; // shape height
  static const int vSpacing = 4; // reduced vertical spacing between shapes
  static const int frameCount =
      0; // 0 indicates an infinite, non-repeating animation

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    // Clear canvas
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    int centerX = badgeWidth ~/ 2;

    // Use birthFrames logic: spawn a new V every vSpacing frames, forever
    final birthFrames = <int>[];
    for (int f = 0; f <= animationIndex; f += vSpacing) {
      birthFrames.add(f);
    }

    double speed = 0.5; // 0.5 = half speed, adjust as needed
    for (final birth in birthFrames) {
      double tipY = animationIndex * speed - birth;
      if (tipY < 0 || tipY - (vHeight - 1) >= badgeHeight) {
        continue; // Only draw if any part is visible
      }

      int y1 = tipY.round();
      int y2 = (tipY - (vHeight - 1)).round();

      // Improved: arms reach the edges exactly when tip reaches the bottom
      int maxArmOffset = centerX;
      double minOffset = 1.0; // or 2.0 for a wider initial V

      double progress = (tipY).clamp(0, badgeHeight - 1) / (badgeHeight - 1);
      int endArmOffset =
          (minOffset + progress * (maxArmOffset - minOffset)).round();

      _drawLine(centerX, y1, centerX - endArmOffset, y2, canvas, badgeWidth,
          badgeHeight);
      _drawLine(centerX, y1, centerX + endArmOffset, y2, canvas, badgeWidth,
          badgeHeight);
    }
  }

  // Simple line drawing function (like Bresenham's) to ensure no gaps
  void _drawLine(int x1, int y1, int x2, int y2, List<List<bool>> canvas,
      int badgeWidth, int badgeHeight) {
    int dx = (x2 - x1).abs();
    int dy = (y2 - y1).abs();
    int sx = (x1 < x2) ? 1 : -1;
    int sy = (y1 < y2) ? 1 : -1;
    int err = dx - dy;

    while (true) {
      if (y1 >= 0 && y1 < badgeHeight && x1 >= 0 && x1 < badgeWidth) {
        canvas[y1][x1] = true;
      }

      if ((x1 == x2) && (y1 == y2)) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }
  }
}
