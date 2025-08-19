import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class FireworksAnimation extends BadgeAnimation {
  static const int badgeHeight = 11;
  static const int badgeWidth = 44;
  static const int hardwareFrameCount = 8;

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

    // Offset so animation starts in the middle of the burst cycle for more variety
    final int frameOffset = hardwareFrameCount ~/ 2;
    final int frame = (animationIndex + frameOffset) % hardwareFrameCount;
    final int sequence = (animationIndex ~/ hardwareFrameCount) % 3;

    // Different positioning patterns
    List<List<Map<String, int>>> positionPatterns = [
      // Pattern 1: Scattered positions
      [
        {"x": 9, "y": 3, "start": 0},
        {"x": 22, "y": 7, "start": 2},
        {"x": 35, "y": 2, "start": 4},
        {"x": 15, "y": 8, "start": 1},
        {"x": 28, "y": 4, "start": 3},
      ],

      // Pattern 2: Wave from left to right
      [
        {"x": 7, "y": 5, "start": 0},
        {"x": 14, "y": 3, "start": 1},
        {"x": 21, "y": 7, "start": 2},
        {"x": 28, "y": 4, "start": 3},
        {"x": 35, "y": 6, "start": 4},
      ],

      // Pattern 3: Center and corners
      [
        {"x": 22, "y": 5, "start": 0}, // Center
        {"x": 8, "y": 2, "start": 2}, // Top left
        {"x": 36, "y": 2, "start": 2}, // Top right
        {"x": 8, "y": 8, "start": 4}, // Bottom left
        {"x": 36, "y": 8, "start": 4}, // Bottom right
      ],
    ];

    // Draw fireworks for current pattern
    for (final fw in positionPatterns[sequence]) {
      _drawSunFirework(canvas, fw, frame, badgeWidth, badgeHeight);
    }
  }

  /// Draw single sun-shaped firework with bursting animation
  void _drawSunFirework(List<List<bool>> canvas, Map<String, int> firework,
      int frame, int badgeWidth, int badgeHeight) {
    int cx = firework["x"]!;
    int cy = firework["y"]!;
    int startFrame = firework["start"]!;

    int localFrame =
        (frame - startFrame + hardwareFrameCount) % hardwareFrameCount;

    // Skip if not active
    if (localFrame == 0 || localFrame > 6) return;

    // Bursting animation - grows in size
    int radius = 0;
    bool fade = false;

    switch (localFrame) {
      case 1: // Small sun
        radius = 1;
        break;
      case 2: // Medium sun
        radius = 2;
        break;
      case 3: // Large sun
        radius = 3;
        break;
      case 4: // Peak size
        radius = 4;
        break;
      case 5: // Start fading
        radius = 4;
        fade = true;
        break;
      case 6: // More fading
        radius = 3;
        fade = true;
        break;
    }

    _drawSunShape(canvas, cx, cy, radius, badgeWidth, badgeHeight, fade, frame);
  }

  /// Draw the sun shape - hollow circle with radiating spikes
  void _drawSunShape(List<List<bool>> canvas, int cx, int cy, int radius,
      int badgeWidth, int badgeHeight, bool fade, int frame) {
    if (radius < 1) return;

    // Draw outer circle (hollow)
    for (double angle = 0; angle < 2 * pi; angle += pi / 8) {
      int x = cx + (radius * cos(angle)).round();
      int y = cy + (radius * sin(angle)).round();

      // Fade effect - skip some pixels
      if (fade && (x + y + frame) % 3 == 0) continue;

      _setPixel(canvas, x, y, badgeWidth, badgeHeight);
    }

    // Draw radiating spikes from the circle
    int spikeCount = 8; // 8 spikes
    for (int i = 0; i < spikeCount; i++) {
      double angle = i * 2 * pi / spikeCount;

      // Spike extends beyond the circle
      int spikeLength = radius + 1;
      if (radius >= 3)
        spikeLength = radius + 2; // Longer spikes for bigger fireworks

      for (int r = radius + 1; r <= spikeLength; r++) {
        int x = cx + (r * cos(angle)).round();
        int y = cy + (r * sin(angle)).round();

        // Fade effect on spikes
        if (fade && (r + i + frame) % 2 == 0) continue;

        _setPixel(canvas, x, y, badgeWidth, badgeHeight);
      }
    }

    // For very small fireworks, also draw inner ring
    if (radius == 1) {
      _setPixel(canvas, cx, cy, badgeWidth, badgeHeight);
    }
  }

  /// Helper to safely set pixels
  void _setPixel(
      List<List<bool>> canvas, int x, int y, int badgeWidth, int badgeHeight) {
    if (x >= 0 && x < badgeWidth && y >= 0 && y < badgeHeight) {
      canvas[y][x] = true;
    }
  }
}
