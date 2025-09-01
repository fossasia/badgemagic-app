import 'package:badgemagic/badge_animation/animation_abstract.dart';

class LeftChevronAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    // Clear canvas
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        canvas[i][j] = false;
      }
    }
    // Compact arrow: 4 columns wide, 7 rows tall
    int arrowWidth = 4;
    int arrowHeight = 7;
    int offset = animationIndex % arrowWidth;
    int arrowTop = (badgeHeight - arrowHeight) ~/ 2;
    // Arrow pattern for a compact '<' (4x7)
    List<List<bool>> arrow = [
      [false, false, false, true],
      [false, false, true, false],
      [false, true, false, false],
      [true, false, false, false],
      [false, true, false, false],
      [false, false, true, false],
      [false, false, false, true],
    ];
    // Draw as many arrows as fit across the width, packed tightly
    for (int arrowIdx = 0;
        arrowIdx < (badgeWidth / arrowWidth).ceil() + 2;
        arrowIdx++) {
      int startCol = badgeWidth - offset - arrowIdx * arrowWidth;
      for (int y = 0; y < arrowHeight; y++) {
        for (int x = 0; x < arrowWidth; x++) {
          int row = arrowTop + y;
          int col = startCol + x;
          if (row >= 0 &&
              row < badgeHeight &&
              col >= 0 &&
              col < badgeWidth &&
              arrow[y][x]) {
            canvas[row][col] = true;
          }
        }
      }
    }
  }
}
