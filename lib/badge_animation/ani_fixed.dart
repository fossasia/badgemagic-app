import 'package:badgemagic/badge_animation/animation_abstract.dart';

class FixedAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newGridHeight = processGrid.length;
    int newGridWidth = processGrid[0].length;

    int horizontalOffset = 0;
    if (newGridWidth < badgeWidth) {
      horizontalOffset = (badgeWidth - newGridWidth) ~/ 2;
    }

    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int sourceCol = j - horizontalOffset;

        bool isWithinNewGrid =
            i < newGridHeight && sourceCol >= 0 && sourceCol < newGridWidth;

        bool animationCondition =
            (isWithinNewGrid && processGrid[i][sourceCol]);

        canvas[i][j] = animationCondition;
      }
    }
  }
}
