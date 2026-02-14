import 'package:badgemagic/badge_animation/animation_abstract.dart';

class FixedAnimation extends BadgeAnimation {
  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    int newWidth = processGrid[0].length;

    // Fixed animation should render content starting from the left edge
    int horizontalOffset = 0;

    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int sourceCol = j - horizontalOffset;

        if (sourceCol >= 0 && sourceCol < newWidth) {
          canvas[i][j] = processGrid[i][sourceCol];
        } else {
          canvas[i][j] = false;
        }
      }
    }
  }
}
