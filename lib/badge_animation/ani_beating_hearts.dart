import 'package:badgemagic/badge_animation/animation_abstract.dart';

class BeatingHeartsAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int hardwareFrameCount = 8;

  // Define heart patterns for different sizes (bigger, more visible hearts)
  static const List<List<String>> heartPatterns = [
    // Size 1 (small heart - 5x4)
    ["## ##", "#####", " ### ", "  #  "],
    // Size 2 (medium heart - 7x6)
    ["### ###", "#######", "#######", " ##### ", "  ###  ", "   #   "],
    // Size 3 (large heart - 9x7) - refined shape
    [
      " ### ### ",
      "#########",
      "#########",
      " #######",
      "  ##### ",
      "   ###  ",
      "    #   "
    ],
    // Size 4 (extra large heart - 11x8) - refined shape
    [
      " #### #### ",
      "###########",
      "###########",
      " ######### ",
      "  ####### ",
      "   #####  ",
      "    ###   ",
      "     #    "
    ]
  ];

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

    // More dramatic heart scale values for better beating animation
    const List<double> heartScales = [0.1, 0.3, 0.5, 0.7, 1.0, 0.7, 0.5, 0.3];
    double scale = heartScales[animationIndex % hardwareFrameCount];

    // Position hearts with better spacing for larger hearts
    int leftHeartCenterX = 11;
    int rightHeartCenterX = 33;
    int centerY = badgeHeight ~/ 2;

    _drawHeart(canvas, leftHeartCenterX, centerY, scale);
    _drawHeart(canvas, rightHeartCenterX, centerY, scale);
  }

  void _drawHeart(List<List<bool>> canvas, int cx, int cy, double scale) {
    // Determine which heart pattern to use based on scale
    int patternIndex;
    if (scale <= 0.2) {
      patternIndex = 0;
    } else if (scale <= 0.4) {
      patternIndex = 1;
    } else if (scale <= 0.7) {
      patternIndex = 2;
    } else {
      patternIndex = 3;
    }

    List<String> pattern = heartPatterns[patternIndex];
    int patternHeight = pattern.length;
    int patternWidth = pattern[0].length;

    int startY = cy - patternHeight ~/ 2;
    int startX = cx - patternWidth ~/ 2;

    for (int py = 0; py < patternHeight; py++) {
      for (int px = 0; px < patternWidth; px++) {
        if (px < pattern[py].length && pattern[py][px] == '#') {
          int actualX = startX + px;
          int actualY = startY + py;

          if (_inBounds(actualX, actualY)) {
            canvas[actualY][actualX] = true;
          }
        }
      }
    }

    if (scale <= 0.1) {
      if (_inBounds(cx, cy)) canvas[cy][cx] = true;
      if (_inBounds(cx - 1, cy)) canvas[cy][cx - 1] = true;
      if (_inBounds(cx + 1, cy)) canvas[cy][cx + 1] = true;
      if (_inBounds(cx, cy - 1)) canvas[cy - 1][cx] = true;
      if (_inBounds(cx, cy + 1)) canvas[cy + 1][cx] = true;
    }
  }

  bool _inBounds(int x, int y) {
    return x >= 0 && x < badgeWidth && y >= 0 && y < badgeHeight;
  }
}
