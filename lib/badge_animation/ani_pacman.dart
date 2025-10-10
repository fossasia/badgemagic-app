import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class PacmanClassicAnimation extends BadgeAnimation {
  static const int numBlocks = 3;
  static const int pacmanRadius = 4;
  static const int foodRadius = 2;
  static const int destructionDuration = 4;

  List<bool> _eatenBlocks = List.filled(numBlocks, false);
  List<int> _destroyFrames = List.filled(numBlocks, -1);
  int _lastLoopIndex = 0;

  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    // Always reset state if starting from the beginning (animationIndex == 0)
    if (animationIndex == 0) {
      _eatenBlocks = List.filled(numBlocks, false);
      _destroyFrames = List.filled(numBlocks, -1);
      _lastLoopIndex = 0;
    }
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        canvas[i][j] = false;
      }
    }
    int pathStart = pacmanRadius + 1;
    int pathEnd = badgeWidth - pacmanRadius - 2;
    int pathLength = pathEnd - pathStart + 1;
    int pacmanRow = badgeHeight ~/ 2;
    int pacmanCol = pathStart + (animationIndex % pathLength);
    int loopIndex = animationIndex ~/ pathLength;
    if (loopIndex != _lastLoopIndex) {
      _eatenBlocks = List.filled(numBlocks, false);
      _destroyFrames = List.filled(numBlocks, -1);
      _lastLoopIndex = loopIndex;
    }
    int blockSpacing = (pathLength / (numBlocks + 1)).floor();
    List<int> blockCols =
        List.generate(numBlocks, (b) => pathStart + (b + 1) * blockSpacing);
    for (int b = 0; b < numBlocks; b++) {
      if (!_eatenBlocks[b] &&
          (pacmanCol - blockCols[b]).abs() <= pacmanRadius) {
        _eatenBlocks[b] = true;
        _destroyFrames[b] = 0;
      }
    }
    for (int b = 0; b < numBlocks; b++) {
      if (_destroyFrames[b] >= 0 && _destroyFrames[b] < destructionDuration) {
        _drawDestroyEffect(canvas, blockCols[b], pacmanRow, _destroyFrames[b],
            badgeWidth, badgeHeight);
        _destroyFrames[b] = _destroyFrames[b] + 1;
      }
    }
    for (int b = 0; b < numBlocks; b++) {
      if (!_eatenBlocks[b] && _destroyFrames[b] < 0) {
        _drawFilledCircle(canvas, blockCols[b], pacmanRow, foodRadius,
            badgeWidth, badgeHeight);
      }
    }
    double minMouth = pi / 10;
    double maxMouth = pi / 1.8;
    int mouthPeriod = 8;
    double t = (animationIndex % mouthPeriod) / mouthPeriod;
    double mouthAngle =
        minMouth + (maxMouth - minMouth) * (0.5 * (1 - cos(2 * pi * t)));
    double mouthDirection = 0;
    _drawPacman(canvas, pacmanCol, pacmanRow, pacmanRadius, mouthAngle,
        mouthDirection, badgeWidth, badgeHeight);
  }

  void _drawFilledCircle(
      List<List<bool>> canvas, int cx, int cy, int radius, int w, int h) {
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        if (x * x + y * y <= radius * radius) {
          int px = cx + x;
          int py = cy + y;
          if (py >= 0 && py < h && px >= 0 && px < w) {
            canvas[py][px] = true;
          }
        }
      }
    }
  }

  void _drawDestroyEffect(
      List<List<bool>> canvas, int cx, int cy, int frame, int w, int h) {
    int length = frame + 1;
    List<List<int>> dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];
    for (var d in dirs) {
      for (int i = 1; i <= length; i++) {
        int px = cx + d[0] * i;
        int py = cy + d[1] * i;
        if (py >= 0 && py < h && px >= 0 && px < w) {
          canvas[py][px] = true;
        }
      }
    }
  }

  void _drawPacman(List<List<bool>> canvas, int cx, int cy, int radius,
      double mouthAngle, double mouthDirection, int w, int h) {
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        if (x * x + y * y <= radius * radius) {
          double angle = atan2(y.toDouble(), x.toDouble());
          if (angle < 0) angle += 2 * pi;
          double start = mouthDirection - mouthAngle / 2;
          double end = mouthDirection + mouthAngle / 2;
          if (start < 0) start += 2 * pi;
          if (end < 0) end += 2 * pi;
          bool inMouth = false;
          if (start < end) {
            inMouth = angle >= start && angle <= end;
          } else {
            inMouth = angle >= start || angle <= end;
          }
          if (!inMouth) {
            int px = cx + x;
            int py = cy + y;
            if (py >= 0 && py < h && px >= 0 && px < w) {
              canvas[py][px] = true;
            }
          }
        }
      }
    }
  }
}
