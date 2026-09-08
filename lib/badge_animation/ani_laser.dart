import 'package:badgemagic/badge_animation/animation_abstract.dart';

class LaserAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;

    int framesCount = (newWidth / badgeWidth).ceil();

    int currentFrame = (animationIndex ~/ badgeWidth) % framesCount;

    int startCol = currentFrame * badgeWidth;

    int horizontalOffset = (badgeWidth - newWidth).clamp(0, badgeWidth) ~/ 2;

    var totalAnimationLength = badgeWidth * 2;
    int frame = animationIndex % totalAnimationLength;
    var firstHalf = frame < badgeWidth;
    var secondHalf = frame >= badgeWidth;
    var index = frame % badgeWidth;

    if (firstHalf) {
      if (index < newWidth) {
        for (int i = 0; i < newHeight; i++) {
          int sourceCol = startCol + index;
          if (sourceCol >= 0 &&
              sourceCol < newWidth &&
              processGrid[i][sourceCol]) {
            int x = index + horizontalOffset;
            while (x < badgeWidth) {
              if (x >= 0 && x < badgeWidth) {
                canvas[i][x] = true;
              }
              x++;
            }
          }
        }
      }

      for (int i = 0; i < index; i++) {
        for (int j = 0; j < badgeHeight; j++) {
          int sourceCol = startCol + i;
          bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
          if (isWithinNewGrid &&
              (i + horizontalOffset) >= 0 &&
              (i + horizontalOffset) < badgeWidth) {
            canvas[j][i + horizontalOffset] = processGrid[j][sourceCol];
          }
        }
      }
    }

    if (secondHalf) {
      if (index < newWidth) {
        for (int i = 0; i < newHeight; i++) {
          for (int x = 0; x < badgeWidth; x++) {
            int sourceCol = startCol + x - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid && x >= 0 && x < badgeWidth) {
              canvas[i][x] = processGrid[i][sourceCol];
            }
          }
        }

        for (int i = 0; i < newHeight; i++) {
          if (startCol + index < newWidth && processGrid[i][startCol + index]) {
            int x = 0;
            while (x < index + horizontalOffset) {
              if (x >= 0 && x < badgeWidth) {
                canvas[i][x] = true;
              }
              x++;
            }
          } else {
            int x = 0;
            while (x < index + horizontalOffset) {
              if (x >= 0 && x < badgeWidth) {
                canvas[i][x] = false;
              }
              x++;
            }
          }
        }
      }
    }
  }
}
