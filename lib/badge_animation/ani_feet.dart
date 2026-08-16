import 'package:badgemagic/badge_animation/animation_abstract.dart';

class FeetAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int footHeight = 6;
  static const int footWidth = 7;
  static const int verticalSpacing = 0;
  static const int stride = 6;

  static final int frameCount = 20;

  static final List<List<bool>> foot = [
    [false, false, false, false, false, false, true],
    [false, false, false, true, true, false, false],
    [false, true, true, false, true, false, true],
    [true, false, false, false, true, false, true],
    [true, true, true, true, true, false, true],
    [false, false, false, false, false, false, false],
  ];

  static void _drawFoot(List<List<bool>> grid, int row, int col) {
    for (int r = 0; r < footHeight; r++) {
      for (int c = 0; c < footWidth; c++) {
        int rr = row + r;
        int cc = col + c;
        if (rr >= 0 &&
            rr < badgeHeight &&
            cc >= 0 &&
            cc < badgeWidth &&
            foot[r][c]) {
          grid[rr][cc] = true;
        }
      }
    }
  }

  int leftX = 0;
  int rightX = stride;

  void _resetFeet() {
    leftX = 0;
    rightX = stride;
  }

  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    final grid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    final yBottom = badgeHeight - footHeight + 1;
    final yTop = yBottom - footHeight - verticalSpacing;

    final isLeftTurn = animationIndex % 2 == 0;
    final maxX = badgeWidth;

    if (leftX > maxX || rightX > maxX) {
      _resetFeet();
    }

    if (isLeftTurn) {
      leftX = rightX + stride;
    } else {
      rightX = leftX + stride;
    }

    _drawFoot(grid, yTop, rightX);
    _drawFoot(grid, yBottom, leftX);

    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        canvas[i][j] = grid[i][j];
      }
    }
  }
}
