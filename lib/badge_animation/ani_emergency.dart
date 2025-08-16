import 'package:badgemagic/badge_animation/animation_abstract.dart';

class EmergencyAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int squareSize = 7;
  static const int hardwareFrameCount = 8;

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    // Clear the canvas
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    int frame = animationIndex % hardwareFrameCount;

    int leftX = 10;
    int rightX = badgeWidth - squareSize - 10;
    int y = (badgeHeight - squareSize) ~/ 2;

    switch (frame) {
      case 0: // Left ON
        _drawSquare(canvas, leftX, y);
        break;
      case 1: // Right ON
        _drawSquare(canvas, rightX, y);
        break;
      case 2: // Left ON
        _drawSquare(canvas, leftX, y);
        break;
      case 3: // Left OFF (blink)
        break;
      case 4: // Left ON
        _drawSquare(canvas, leftX, y);
        break;
      case 5: // Right ON
        _drawSquare(canvas, rightX, y);
        break;
      case 6: // Right OFF (blink)
        break;
      case 7: // Right ON
        _drawSquare(canvas, rightX, y);
        break;
    }
  }

  void _drawSquare(List<List<bool>> canvas, int startX, int startY) {
    for (int y = 0; y < squareSize; y++) {
      for (int x = 0; x < squareSize; x++) {
        int px = startX + x;
        int py = startY + y;
        if (px >= 0 && px < badgeWidth && py >= 0 && py < badgeHeight) {
          canvas[py][px] = true;
        }
      }
    }
  }
}
