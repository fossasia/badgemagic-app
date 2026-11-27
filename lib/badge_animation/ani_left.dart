import 'package:badgemagic/badge_animation/animation_abstract.dart';

class LeftAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    if (processGrid.isEmpty) {
      return;
    }
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;
    if (newWidth == 0 || newHeight == 0) {
      return;
    }
    int scrollOffset = animationIndex % newWidth;
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int sourceCol = (j + scrollOffset) % newWidth;
        canvas[i][j] = processGrid[i % newHeight][sourceCol];
      }
    }
  }
}
