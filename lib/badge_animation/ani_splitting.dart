import 'package:badgemagic/badge_animation/animation_abstract.dart';

class SplittingAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newGridHeight = processGrid.length;
    int newGridWidth = processGrid[0].length;
    final int frameStride =
        (newGridWidth > badgeWidth && newGridWidth % 48 == 0) ? 48 : badgeWidth;

    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int framesCount = (newGridWidth / frameStride).ceil();
        if (framesCount == 0) framesCount = 1;

        int currentcountFrame = animationIndex ~/ badgeWidth % framesCount;

        int startCol = currentcountFrame * frameStride;

        bool isNewGridCell = i < newGridHeight && (startCol + j) < newGridWidth;

        bool animationCondition =
            (isNewGridCell && processGrid[i][startCol + j]);

        canvas[i][j] = animationCondition;
      }
    }
  }
}
