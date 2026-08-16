import 'package:badgemagic/badge_animation/animation_abstract.dart';

class LeftAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int scrollOffset = animationIndex % (newWidth + badgeWidth);

        int sourceCol = j + scrollOffset - badgeWidth;

        if (sourceCol >= 0 && sourceCol < newWidth) {
          canvas[i][j] = processGrid[i % newHeight][sourceCol];
        }
      }
    }
  }
}
