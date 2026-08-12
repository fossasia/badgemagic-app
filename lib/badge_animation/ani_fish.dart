import 'package:badgemagic/badge_animation/animation_abstract.dart';

class FishAnimation extends BadgeAnimation {
  List<List<List<bool>>> transferFrames() {
    List<List<List<bool>>> frames = [];
    for (int animationIndex = 0; animationIndex < 8; animationIndex++) {
      List<List<bool>> canvas =
          List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
      int phase = animationIndex;
      int gap = phase <= (gapMax - gapMin)
          ? gapMax - phase
          : gapMin + (phase - (gapMax - gapMin));
      int centerX = (badgeWidth - (2 * fishWidth + gap)) ~/ 2;
      int leftFishX = centerX;
      int rightFishX = leftFishX + fishWidth + gap;
      int fishY = 0;
      _drawFish(canvas, fishY, leftFishX, flip: false);
      _drawFish(canvas, fishY, rightFishX, flip: true);
      int baseKissY = fishY + fishHeight ~/ 2;
      int centerXWhenKissing = (badgeWidth - (2 * fishWidth + gapMin)) ~/ 2;
      int kissX = centerXWhenKissing + fishWidth;
      bool hasKissed = phase >= (gapMax - gapMin);
      if (gap == gapMin) {
        _draw2x2Block(canvas, baseKissY, kissX);
      } else if (hasKissed && gap > gapMin) {
        int upwardOffset = ((gap - gapMin) * 3) ~/ (gapMax - gapMin);
        int upwardKissY = baseKissY - upwardOffset;
        int downwardKissY = baseKissY + upwardOffset;
        if (upwardOffset < 2) {
          _draw2x2Block(canvas, upwardKissY, kissX);
          _draw2x2Block(canvas, downwardKissY, kissX);
        } else {
          _drawSparkleEffect(canvas, upwardKissY, kissX, animationIndex);
          _drawSparkleEffect(canvas, downwardKissY, kissX, animationIndex);
        }
      }
      frames.add(canvas);
    }
    return frames;
  }

  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int fishHeight = 11;
  static const int fishWidth = 14;
  static const int gapMin = 0;
  static const int gapMax = 8;
  static const int framesPerCycle = (gapMax - gapMin) * 2;

  static final List<List<int>> crosswordMatrix = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0],
    [0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1],
    [0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1],
    [0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0],
    [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
    [1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    int phase = animationIndex % framesPerCycle;
    int gap = phase < (gapMax - gapMin)
        ? gapMax - phase
        : gapMin + (phase - (gapMax - gapMin));

    int centerX = (badgeWidth - (2 * fishWidth + gap)) ~/ 2;
    int leftFishX = centerX;
    int rightFishX = leftFishX + fishWidth + gap;
    int fishY = 0;

    _drawFish(canvas, fishY, leftFishX, flip: false);
    _drawFish(canvas, fishY, rightFishX, flip: true);

    int baseKissY = fishY + fishHeight ~/ 2;

    int centerXWhenKissing = (badgeWidth - (2 * fishWidth + gapMin)) ~/ 2;
    int kissX = centerXWhenKissing + fishWidth;

    bool hasKissed = phase >= (gapMax - gapMin);

    if (gap == gapMin) {
      _draw2x2Block(canvas, baseKissY, kissX);
    } else if (hasKissed && gap > gapMin) {
      int upwardOffset = ((gap - gapMin) * 3) ~/ (gapMax - gapMin);
      int upwardKissY = baseKissY - upwardOffset;
      int downwardKissY = baseKissY + upwardOffset;

      if (upwardOffset < 2) {
        _draw2x2Block(canvas, upwardKissY, kissX);
        _draw2x2Block(canvas, downwardKissY, kissX);
      } else {
        _drawSparkleEffect(
            canvas, upwardKissY, kissX, animationIndex);
        _drawSparkleEffect(canvas, downwardKissY, kissX,
            animationIndex);
      }
    }
  }

  void _draw2x2Block(List<List<bool>> canvas, int centerY, int centerX) {
    for (int dy = -1; dy <= 0; dy++) {
      for (int dx = -1; dx <= 0; dx++) {
        int sx = centerX + dx;
        int sy = centerY + dy;
        if (sy >= 0 && sy < badgeHeight && sx >= 0 && sx < badgeWidth) {
          canvas[sy][sx] = true;
        }
      }
    }
  }

  void _drawSparkleEffect(
      List<List<bool>> canvas, int centerY, int centerX, int animationIndex) {
    final sparklePatterns = [
      [
        [0, 0],
        [-2, 0],
        [2, 0],
        [0, -2],
        [0, 2]
      ],
      [
        [0, 0],
        [-2, -2],
        [-2, 2],
        [2, -2],
        [2, 2]
      ],
      [
        [-3, 0],
        [3, 0],
        [0, -3],
        [0, 3]
      ],
      [
        [-2, 0],
        [2, 0],
        [0, -2],
        [0, 2],
        [-3, -1],
        [3, 1],
        [-1, -3],
        [1, 3]
      ],
      [
        [-1, -2],
        [1, -2],
        [-2, -1],
        [2, -1],
        [-2, 1],
        [2, 1],
        [-1, 2],
        [1, 2]
      ],
    ];

    int sparkleFrame = (animationIndex ~/ 3) % sparklePatterns.length;

    for (final offset in sparklePatterns[sparkleFrame]) {
      int sx = centerX + offset[1];
      int sy = centerY + offset[0];
      if (sy >= 0 && sy < badgeHeight && sx >= 0 && sx < badgeWidth) {
        canvas[sy][sx] = true;
      }
    }
  }

  void _drawFish(List<List<bool>> grid, int top, int left,
      {bool flip = false}) {
    for (int y = 0; y < fishHeight; y++) {
      for (int x = 0; x < fishWidth; x++) {
        if (crosswordMatrix[y][x] == 1) {
          int drawX = flip ? (left + fishWidth - 1 - x) : (left + x);
          int drawY = top + y;
          if (drawY >= 0 &&
              drawY < badgeHeight &&
              drawX >= 0 &&
              drawX < badgeWidth) {
            grid[drawY][drawX] = true;
          }
        }
      }
    }
  }
}
