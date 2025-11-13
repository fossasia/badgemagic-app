import 'package:badgemagic/badge_animation/animation_abstract.dart';

class SnowFlakeAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    // Simplified falling behavior:
    // Move the entire processGrid downwards one row per frame. The image
    // enters from the top and exits at the bottom. This mapping keeps frame
    // ordering consistent with the animation timer (one tick == one frame).
    final int newHeight = processGrid.length;
    final int newWidth = processGrid[0].length;

    // Total frames needed for the source to fully pass through the badge
    final int totalFrames = badgeHeight + newHeight;
    final int frame = (totalFrames > 0) ? (animationIndex % totalFrames) : 0;

    final int horizontalOffset = (badgeWidth - newWidth) ~/ 2;

    // For each source cell, compute its destination row for current frame.
    for (int srcRow = 0; srcRow < newHeight; srcRow++) {
      for (int srcCol = 0; srcCol < newWidth; srcCol++) {
        if (!processGrid[srcRow][srcCol]) continue;

        // Destination row where this source pixel should appear this frame.
        int destRow = frame - srcRow;
        int destCol = horizontalOffset + srcCol;

        if (destRow >= 0 && destRow < badgeHeight && destCol >= 0 && destCol < badgeWidth) {
          canvas[destRow][destCol] = true;
        }
      }
    }
  }
}
