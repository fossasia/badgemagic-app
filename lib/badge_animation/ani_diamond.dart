import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class DiamondAnimation extends BadgeAnimation {
  /// frames between each new diamond spawn
  /// ↓ smaller → more diamonds onscreen at once
  static const int spawnInterval = 4;

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    final int midX = badgeWidth ~/ 2;
    final int cx1 = badgeWidth ~/ 4;
    final int cx2 = 3 * badgeWidth ~/ 4;
    final int cy = badgeHeight ~/ 2;
    final int maxDx1 = min(cx1, badgeWidth - 1 - cx1);
    final int maxDx2 = min(cx2, badgeWidth - 1 - cx2);
    final int maxDy = min(cy, badgeHeight - 1 - cy);

    final birthFrames = <int>[];
    for (int f = 0; f <= animationIndex; f += spawnInterval) {
      birthFrames.add(f);
    }

    void drawLine(int x0, int y0, int x1, int y1, bool isLeft) {
      int dx = (x1 - x0).abs();
      int sx = x0 < x1 ? 1 : -1;
      int dy = -(y1 - y0).abs();
      int sy = y0 < y1 ? 1 : -1;
      int err = dx + dy;

      while (true) {
        if (x0 >= 0 && x0 < badgeWidth && y0 >= 0 && y0 < badgeHeight) {
          bool inMyHalf = isLeft ? (x0 < midX) : (x0 >= midX);
          if (inMyHalf && !canvas[y0][x0]) {
            canvas[y0][x0] = true;
          }
        }
        if (x0 == x1 && y0 == y1) break;
        int e2 = err * 2;
        if (e2 >= dy) {
          err += dy;
          x0 += sx;
        }
        if (e2 <= dx) {
          err += dx;
          y0 += sy;
        }
      }
    }

    void drawDiamond(int cx, int cy, int r, int maxDx, bool isLeft) {
      int ry = r;
      int rx = (maxDy > 0) ? ((r * maxDx) / maxDy).round() : r;

      drawLine(cx, cy - ry, cx + rx, cy, isLeft);
      drawLine(cx + rx, cy, cx, cy + ry, isLeft);
      drawLine(cx, cy + ry, cx - rx, cy, isLeft);
      drawLine(cx - rx, cy, cx, cy - ry, isLeft);
    }

    for (final birth in birthFrames) {
      final int r = animationIndex - birth;
      if (r < 0) continue;
      drawDiamond(cx1, cy, r, maxDx1, true);
      drawDiamond(cx2, cy, r, maxDx2, false);
    }
  }
}
