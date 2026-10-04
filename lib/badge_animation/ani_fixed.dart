import 'package:badgemagic/badge_animation/animation_abstract.dart';

class FixedAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    final int newWidth = processGrid[0].length;

    // Fixed mode should render flush-left. Centering introduced unintended
    // left padding (see #1557).
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        if (j < newWidth) {
          canvas[i][j] = processGrid[i][j];
        } else {
          canvas[i][j] = false;
        }
      }
    }
  }
}
