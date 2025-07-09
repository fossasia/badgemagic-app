import 'package:badgemagic/badge_animation/animation_abstract.dart';

class AniAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int contentWidth = processGrid[0].length;
    int contentHeight = processGrid.length;
    int verticalOffset = (badgeHeight - contentHeight) ~/ 2;

    // How many pixels to shift left for this frame
    int scrollOffset = animationIndex % (contentWidth + badgeWidth);

    // Clear the canvas
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        canvas[i][j] = false;
      }
    }

    // Draw up to two copies of the content for seamless marquee effect
    for (int copy = 0; copy < 2; copy++) {
      int baseX = badgeWidth - scrollOffset + copy * contentWidth;
      for (int y = 0; y < contentHeight; y++) {
        int canvasY = y + verticalOffset;
        if (canvasY < 0 || canvasY >= badgeHeight) continue;
        for (int x = 0; x < contentWidth; x++) {
          int canvasX = baseX + x;
          if (canvasX < 0 || canvasX >= badgeWidth) continue;
          if (processGrid[y][x]) {
            canvas[canvasY][canvasX] = true;
          }
        }
      }
    }
  }
}
