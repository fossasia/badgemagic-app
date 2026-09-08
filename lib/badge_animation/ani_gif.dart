import 'package:badgemagic/badge_animation/animation_abstract.dart';

class GifBadgeAnimation implements BadgeAnimation {
  final List<List<List<bool>>> frames;

  GifBadgeAnimation(this.frames);

  @override
  void processAnimation(int badgeHeight, int badgeWidth, int animationIndex,
      List<List<bool>> processGrid, List<List<bool>> canvas) {
    if (frames.isEmpty) return;
    final frame = frames[animationIndex % frames.length];
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        final bool on = y < frame.length && x < frame[y].length && frame[y][x];
        canvas[y][x] = on;
      }
    }
  }
}
