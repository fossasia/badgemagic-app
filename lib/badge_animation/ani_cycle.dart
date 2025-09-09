import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class CycleAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int cycleHeight = 11;
  static const int cycleWidth = 20;
  static const int framesPerCycle =
      8; // Total frames for complete back-and-forth movement (4 frames each direction)
  static const int previewFramesPerCycle =
      64; // Much more frames for ultra-smooth preview animation with wheel bounce

  // Bicycle pattern matrix - 11x20 grid representing a bicycle
  // 1 = LED on, 0 = LED off
  static final List<List<int>> cycleMatrix = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], // Row 0 - Top
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
    ], // Row 1 - Handlebars
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
    ], // Row 2 - Upper frame
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
    ], // Row 3 - Main frame
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
    ], // Row 4 - Wheels & frame
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
    ], // Row 5 - Wheel centers
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
    ], // Row 6 - Lower wheels
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
    ], // Row 7 - Bottom frame
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
    ], // Row 8 - Ground
    [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0]
  ];

  // Transfer function for badge: generate 8 frames from the infinite animation
  List<List<List<bool>>> transferFrames() {
    List<List<List<bool>>> frames = [];

    // Pick 8 frames from the infinite sequence for transfer
    // Based on analysis:
    // Left-to-right fully visible: frames 13-18 (positions 3-21)
    // Right-to-left fully visible: frames 45-50 (positions 3-21)
    // Frame 1-4: Cycle moving left to right (fully visible)
    // Frame 5-8: Cycle moving right to left (fully visible, flipped)
    List<int> transferFrameIndices = [12, 15, 17, 18, 45, 47, 49, 50];

    for (int i = 0; i < transferFrameIndices.length; i++) {
      int animationIndex = transferFrameIndices[i];

      // Each frame is badgeHeight x badgeWidth
      List<List<bool>> canvas =
          List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));

      // Calculate position for this frame
      int cycleX = _calculateCycleX(animationIndex);
      int cycleY =
          0 + _calculateWheelBounce(animationIndex); // Add wheel bounce effect

      // Draw the cycle at the calculated position
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
    // Clear canvas
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    // Calculate cycle position for this frame (infinite back and forth movement)
    int cycleX = _calculateCycleX(animationIndex);
    int cycleY =
        0 + _calculateWheelBounce(animationIndex); // Add wheel bounce effect

    // Draw the cycle
    _drawCycle(canvas, cycleY, cycleX, flip: _shouldFlipCycle(animationIndex));
  }

  int _calculateCycleX(int animationIndex) {
    // Calculate x position for the cycle
    // Move back and forth: left to right, then right to left (infinite)
    int frame = animationIndex % previewFramesPerCycle;

    if (frame < previewFramesPerCycle / 2) {
      // First half: left to right
      double progress = frame / (previewFramesPerCycle / 2 - 1); // 0.0 to 1.0
      // Use smooth easing for more natural movement
      double easedProgress = _easeInOut(progress);
      int startX = -cycleWidth;
      int endX = badgeWidth;
      int cycleX = startX + (easedProgress * (endX - startX)).round();
      return cycleX;
    } else {
      // Second half: right to left
      double progress = (frame - previewFramesPerCycle / 2) /
          (previewFramesPerCycle / 2 - 1); // 0.0 to 1.0
      // Use smooth easing for more natural movement
      double easedProgress = _easeInOut(progress);
      int startX = badgeWidth;
      int endX = -cycleWidth;
      int cycleX = startX + (easedProgress * (endX - startX)).round();
      return cycleX;
    }
  }

  double _easeInOut(double t) {
    // Smooth easing function for more natural movement
    // This creates acceleration and deceleration instead of linear movement
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  bool _shouldFlipCycle(int animationIndex) {
    // Determine if cycle should be flipped based on direction
    int frame = animationIndex % previewFramesPerCycle;
    return frame >= previewFramesPerCycle / 2; // Flip when moving right to left
  }

  int _calculateWheelBounce(int animationIndex) {
    // Add subtle wheel bounce effect to simulate tire rolling
    int frame = animationIndex % previewFramesPerCycle;
    double progress = frame / previewFramesPerCycle;
    // Create a gentle sine wave bounce effect
    double bounce = sin(progress * 2 * pi) * 0.5;
    return bounce.round();
  }

  void _drawCycle(List<List<bool>> canvas, int top, int left,
      {bool flip = false}) {
    // Draw the bicycle pattern
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
