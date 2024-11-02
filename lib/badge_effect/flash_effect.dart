import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';

class FlashEffect extends BadgeEffect {
  @override
  int get hashCode => 'FlashEffect'.hashCode;

  @override
  bool operator ==(Object other) {
    return other is FlashEffect;
  }

  @override
  void processEffect(int animationIndex, List<List<bool>> canvas,
      int badgeHeight, int badgeWidth) {
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int aIFlash = animationIndex % 8;
        var flashLEDOn = aIFlash < 4;
        canvas[i][j] = canvas[i][j] && flashLEDOn;
      }
    }
  }
}
