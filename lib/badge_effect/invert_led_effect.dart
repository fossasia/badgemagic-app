import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';

class InvertLEDEffect extends BadgeEffect {
  @override
  int get hashCode => 'InvertLEDEffect'.hashCode;

  @override
  bool operator ==(Object other) {
    return other is InvertLEDEffect;
  }

  @override
  void processEffect(int animationIndex, List<List<bool>> canvas,
      int badgeHeight, int badgeWidth) {
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        canvas[i][j] = !canvas[i][j];
      }
    }
  }
}
