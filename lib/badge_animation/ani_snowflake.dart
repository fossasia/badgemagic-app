import 'package:badgemagic/badge_animation/animation_abstract.dart';

class SnowFlakeAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;

    // Calculate the total number of frames that fit the badge width
    int framesCount = (newWidth / badgeWidth).ceil();

    // Calculate the total animation length for one complete snowflake cycle
    int snowflakeCycleLength = badgeHeight * 16;

    // For transfer optimization: limit to 8 frames maximum
    int maxFrames = 8;
    int effectiveFramesCount = framesCount.clamp(1, maxFrames);

    // Calculate the total length for one complete text scroll cycle
    int totalCycleLength = snowflakeCycleLength * effectiveFramesCount;

    // Get the current position in the overall cycle
    int cyclePosition = animationIndex % totalCycleLength;

    // Determine which text section we're currently showing
    int currentFrame = cyclePosition ~/ snowflakeCycleLength;

    // Calculate the starting column for the current frame in newGrid
    int startCol = currentFrame * badgeWidth;

    // Get the frame within the current snowflake cycle
    int frame = cyclePosition % snowflakeCycleLength;

    int horizontalOffset = (badgeWidth - newWidth).clamp(0, badgeWidth) ~/ 2;

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
            int sourceCol = startCol + col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid && row < newHeight) {
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
            int sourceCol = startCol + col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid && row < newHeight) {
              canvas[row][col] = processGrid[row][sourceCol];
            }
          }
        }

        if (fallOutPosition >= row && fallOutPosition < badgeHeight) {
          for (int col = 0; col < badgeWidth; col++) {
            canvas[row][col] = false;
          }

          for (int col = 0; col < badgeWidth; col++) {
            int sourceCol = startCol + col - horizontalOffset;
            bool isWithinNewGrid = sourceCol >= 0 && sourceCol < newWidth;
            if (isWithinNewGrid &&
                fallOutPosition < badgeHeight &&
                row < newHeight) {
              canvas[fallOutPosition][col] = processGrid[row][sourceCol];
            }
          }
        }
      }
    }
  }
}
