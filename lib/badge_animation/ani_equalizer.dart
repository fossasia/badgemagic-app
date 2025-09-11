import 'dart:math';
import 'package:badgemagic/badge_animation/animation_abstract.dart';

/// An animation that simulates a graphic equalizer with bouncing vertical bars.
class EqualizerAnimation extends BadgeAnimation {
  // --- Animation Parameters ---
  /// The width of each vertical bar in pixels.
  static const int barWidth = 4;

  /// The width of the gap between each bar.
  static const int gapWidth = 1;

  /// The probability (0.0 to 1.0) that a bar will change its height on any given frame.
  static const double changeChance = 0.7;

  /// The probability that instead of smoothing, a bar completely resets to a random height.
  static const double resetChance = 0.15;

  final List<int> _barHeights = [];
  bool _initialized = false;
  final Random _rng = Random();

  void _initialize(int badgeHeight, int badgeWidth) {
    if (_initialized) return;
    _initialized = true;

    final int numberOfBars = (badgeWidth + gapWidth) ~/ (barWidth + gapWidth);
    for (int i = 0; i < numberOfBars; i++) {
      _barHeights.add(_rng.nextInt(badgeHeight) + 1);
    }
  }

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    _initialize(badgeHeight, badgeWidth);

    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    final int numberOfBars = (badgeWidth + gapWidth) ~/ (barWidth + gapWidth);

    for (int i = 0; i < numberOfBars; i++) {
      if (_rng.nextDouble() < changeChance) {
        if (_rng.nextDouble() < resetChance) {
          // Hard reset → instant jump
          _barHeights[i] = _rng.nextInt(badgeHeight) + 1;
        } else {
          // This will do Smooth transition toward a random target
          double target = _rng.nextInt(badgeHeight).toDouble();
          _barHeights[i] = (_barHeights[i] * 0.7 + target * 0.3)
              .round()
              .clamp(1, badgeHeight);
        }
      }
    }

    // this draws the bars
    for (int i = 0; i < numberOfBars; i++) {
      int barHeight = _barHeights[i];
      int startX = i * (barWidth + gapWidth);

      for (int y = badgeHeight - 1; y >= badgeHeight - barHeight; y--) {
        for (int x = startX; x < startX + barWidth; x++) {
          if (y >= 0 && y < badgeHeight && x >= 0 && x < badgeWidth) {
            canvas[y][x] = true;
          }
        }
      }
    }
  }
}
