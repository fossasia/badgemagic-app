import 'package:badgemagic/badge_animation/animation_abstract.dart';

class SnowFlakeAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int totalAnimationLength = badgeHeight * 16;
    int frame = animationIndex % totalAnimationLength;

    int horizontalOffset = (badgeWidth - newWidth) ~/ 2;

    bool phase1 = frame < badgeHeight * 4;
    bool phase2 = frame >= badgeHeight * 4 && frame < badgeHeight * 8;

    if (phase1) {
      for (int row = badgeHeight - 1; row >= 0; row--) {
        int fallPosition = frame - (badgeHeight - 1 - row) * 2;
        int stoppingPosition = row;
        fallPosition =
            fallPosition >= stoppingPosition ? stoppingPosition : fallPosition;

        if (fallPosition >= 0 && fallPosition < badgeHeight) {
          for (int col = 0; col < badgeWidth; col++) {
            int sourceCol = col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid) {
              canvas[fallPosition][col] = processGrid[row][sourceCol];
            }
          }
        }
      }
    } else if (phase2) {
      for (int row = badgeHeight - 1; row >= 0; row--) {
        int fallOutStartFrame = (badgeHeight - 1 - row) * 2;
        int fallOutPosition =
            row + (frame - badgeHeight * 4 - fallOutStartFrame);

        if (fallOutPosition < row) {
          for (int col = 0; col < badgeWidth; col++) {
            int sourceCol = col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid) {
              canvas[row][col] = processGrid[row][sourceCol];
            }
          }
        }

        if (fallOutPosition >= row && fallOutPosition < badgeHeight) {
          for (int col = 0; col < badgeWidth; col++) {
            canvas[row][col] = false;
          }

          for (int col = 0; col < badgeWidth; col++) {
            int sourceCol = col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid && fallOutPosition < badgeHeight) {
              canvas[fallOutPosition][col] = processGrid[row][sourceCol];
            }
          }
        }
      }
    }
  }
}
