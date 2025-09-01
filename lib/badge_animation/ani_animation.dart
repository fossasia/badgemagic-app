import 'package:badgemagic/badge_animation/animation_abstract.dart';

class AniAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newGridHeight = processGrid.length;
    int newGridWidth = processGrid[0].length;
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        // Calculate the total number of frames that fit the badge width
        int framesCount = (newGridWidth / badgeWidth).ceil();

        // Determine the current frame based on the animation value
        int currentcountFrame = animationIndex ~/ badgeWidth % framesCount;

        // Calculate the starting column for the current frame in newGrid
        int startCol = currentcountFrame * badgeWidth;

        bool isNewGridCell = i < newGridHeight && (startCol + j) < newGridWidth;

        // Update the grid based on the current frame's data
        bool animationCondition =
            (isNewGridCell && processGrid[i][startCol + j]);

        canvas[i][j] = animationCondition;
      }
    }
  }
}
