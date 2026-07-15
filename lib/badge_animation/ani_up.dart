import 'package:badgemagic/badge_animation/animation_abstract.dart';

class UpAnimation extends BadgeAnimation {
  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    int newWidth = processGrid[0].length;
    int newHeight = processGrid.length;

    bool isTextTooLong = newWidth > badgeWidth;

    int totalPages = 1;
    int currentPage = 0;
    int startColOffset = 0;
    int horizontalOffset = 0;

    int holdDuration = 15;

    int singlePageDuration = (badgeHeight * 2) + holdDuration;

    if (isTextTooLong) {
      totalPages = (newWidth / badgeWidth).ceil();
      if (totalPages == 0) totalPages = 1;
      currentPage = (animationIndex ~/ singlePageDuration) % totalPages;
      startColOffset = currentPage * badgeWidth;
    } else {
      horizontalOffset = (badgeWidth - newWidth) ~/ 2;
    }

    int localFrame = animationIndex % singlePageDuration;
    int verticalScrollOffset;

    if (localFrame < badgeHeight) {
      verticalScrollOffset = badgeHeight - localFrame;
    } else if (localFrame >= badgeHeight &&
        localFrame < (badgeHeight + holdDuration)) {
      verticalScrollOffset = 0;
    } else {
      verticalScrollOffset = -(localFrame - badgeHeight - holdDuration);
    }

    for (int i = 0; i < badgeHeight; i++) {
      int sourceRow = i - verticalScrollOffset;

      for (int j = 0; j < badgeWidth; j++) {
        int sourceCol =
            isTextTooLong ? (startColOffset + j) : (j - horizontalOffset);

        bool isWithinGrid = sourceRow >= 0 &&
            sourceRow < newHeight &&
            sourceCol >= 0 &&
            sourceCol < newWidth;

        if (isWithinGrid) {
          canvas[i][j] = processGrid[sourceRow][sourceCol];
        } else {
          canvas[i][j] = false;
        }
      }
    }
  }
}
