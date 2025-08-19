import 'package:badgemagic/badge_animation/animation_abstract.dart';

class PictureAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;
    int verticalOffset = (badgeHeight - newHeight) ~/ 2;
    int displayWidth = newWidth > badgeWidth ? badgeWidth : newWidth;
    int horizontalOffset = (badgeWidth - displayWidth) ~/ 2;
    var totalAnimationLength = badgeWidth;
    int frame = animationIndex % totalAnimationLength;
    var firstHalf = frame < badgeWidth ~/ 2;
    var secondHalf = frame >= badgeWidth ~/ 2;

    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        bool lineShow = false;
        bool bitmapShowcenter = false;
        bool bitmapShowOut = false;

        int sourceRow = i - verticalOffset;
        int sourceCol = j - horizontalOffset;

        bool isWithinNewGrid = sourceRow >= 0 &&
            sourceRow < newHeight &&
            sourceCol >= 0 &&
            sourceCol < displayWidth;

        int leftCenterCol = badgeWidth ~/ 2 - 1;
        int rightCenterCol = badgeWidth ~/ 2;

        int maxDistance = leftCenterCol;

        int currentAnimationIndex = animationIndex % (maxDistance + 1);

        int leftColPos = leftCenterCol - currentAnimationIndex;
        int rightColPos = rightCenterCol + currentAnimationIndex;

        if (leftColPos < 0) leftColPos += badgeWidth;
        if (rightColPos >= badgeWidth) rightColPos -= badgeWidth;

        if (j == leftColPos || j == rightColPos) {
          lineShow = true;
        } else {
          lineShow = false;
        }

        if (firstHalf) {
          if (isWithinNewGrid && j > leftColPos && j < rightColPos) {
            bitmapShowcenter = processGrid[sourceRow][sourceCol];
          }
        }
        if (secondHalf) {
          if (isWithinNewGrid && (j < leftColPos || j > rightColPos)) {
            bitmapShowOut = processGrid[sourceRow][sourceCol];
          }
        }

        canvas[i][j] = (lineShow || bitmapShowOut || bitmapShowcenter);
      }
    }
  }
}
