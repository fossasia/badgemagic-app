import 'package:badgemagic/badge_animation/animation_abstract.dart';

class AniAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newGridHeight = processGrid.length;
    int newGridWidth = processGrid[0].length;
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        // Calculate the total number of frames available in the source grid
        // (each frame is badgeWidth wide)
        int framesCount = (newGridWidth / badgeWidth).ceil();

        // Determine the current frame based on the animation index.
        // The provider increments animationIndex once per timer tick, so
        // use modulo to select the correct frame (one tick = one frame).
        int currentFrame = (framesCount > 0) ? (animationIndex % framesCount) : 0;

        // Calculate the starting column for the current frame in processGrid
        int startCol = currentFrame * badgeWidth;

        // Check bounds and copy the corresponding cell from processGrid
        bool isNewGridCell = i < newGridHeight && (startCol + j) < newGridWidth;
        canvas[i][j] = (isNewGridCell && processGrid[i][startCol + j]);
      }
    }
  }
}
