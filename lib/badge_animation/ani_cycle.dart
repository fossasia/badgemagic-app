import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class CycleAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int cycleHeight = 11;
  static const int cycleWidth = 20;
  static const int framesPerCycle =
      8;
  static const int previewFramesPerCycle =
      64;

  static final List<List<int>> cycleMatrix = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
    [
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      1,
      0,
      0,
      0
    ],
    [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0
    ],
    [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0
    ],
    [
      0,
      0,
      0,
      1,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      0,
      0,
      1,
      1,
      1,
      0,
      0
    ],
    [
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      0
    ],
    [
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1
    ],
    [
      0,
      1,
      0,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      0,
      0,
      1,
      1,
      1,
      0,
      1
    ],
    [
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      1
    ],
    [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0]
  ];

  List<List<List<bool>>> transferFrames() {
    List<List<List<bool>>> frames = [];

    List<int> transferFrameIndices = [12, 15, 17, 18, 45, 47, 49, 50];

    for (int i = 0; i < transferFrameIndices.length; i++) {
      int animationIndex = transferFrameIndices[i];

      List<List<bool>> canvas =
          List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));

      int cycleX = _calculateCycleX(animationIndex);
      int cycleY =
          0 + _calculateWheelBounce(animationIndex);

      _drawCycle(canvas, cycleY, cycleX,
          flip: _shouldFlipCycle(animationIndex));

      frames.add(canvas);
    }
    return frames;
  }

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

    int cycleX = _calculateCycleX(animationIndex);
    int cycleY =
        0 + _calculateWheelBounce(animationIndex);

    _drawCycle(canvas, cycleY, cycleX, flip: _shouldFlipCycle(animationIndex));
  }

  int _calculateCycleX(int animationIndex) {
    int frame = animationIndex % previewFramesPerCycle;

    if (frame < previewFramesPerCycle / 2) {
      double progress = frame / (previewFramesPerCycle / 2 - 1);
      double easedProgress = _easeInOut(progress);
      int startX = -cycleWidth;
      int endX = badgeWidth;
      int cycleX = startX + (easedProgress * (endX - startX)).round();
      return cycleX;
    } else {
      double progress = (frame - previewFramesPerCycle / 2) /
          (previewFramesPerCycle / 2 - 1);
      double easedProgress = _easeInOut(progress);
      int startX = badgeWidth;
      int endX = -cycleWidth;
      int cycleX = startX + (easedProgress * (endX - startX)).round();
      return cycleX;
    }
  }

  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  bool _shouldFlipCycle(int animationIndex) {
    int frame = animationIndex % previewFramesPerCycle;
    return frame >= previewFramesPerCycle / 2;
  }

  int _calculateWheelBounce(int animationIndex) {
    int frame = animationIndex % previewFramesPerCycle;
    double progress = frame / previewFramesPerCycle;
    double bounce = sin(progress * 2 * pi) * 0.5;
    return bounce.round();
  }

  void _drawCycle(List<List<bool>> canvas, int top, int left,
      {bool flip = false}) {
    for (int y = 0; y < cycleHeight; y++) {
      for (int x = 0; x < cycleWidth; x++) {
        if (cycleMatrix[y][x] == 1) {
          int drawX = flip ? (left + cycleWidth - 1 - x) : (left + x);
          int drawY = top + y;
          if (drawY >= 0 &&
              drawY < badgeHeight &&
              drawX >= 0 &&
              drawX < badgeWidth) {
            canvas[drawY][drawX] = true;
          }
        }
      }
    }
  }
}
