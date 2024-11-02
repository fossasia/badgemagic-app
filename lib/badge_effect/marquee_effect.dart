import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';

class MarqueeEffect extends BadgeEffect {
  @override
  int get hashCode => 'MarqueeEffect'.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MarqueeEffect;
  }

  @override
  void processEffect(int animationIndex, List<List<bool>> canvas,
      int badgeHeight, int badgeWidth) {
    for (int i = 0; i < badgeHeight; i++) {
      for (int j = 0; j < badgeWidth; j++) {
        int aIMarquee = animationIndex ~/ 2;
        var validMarquee =
            (i == 0 || j == 0 || i == badgeHeight - 1 || j == badgeWidth - 1);

        if (validMarquee) {
          if ((i == 0 || j == badgeWidth - 1) &&
              !(i == badgeHeight - 1 && j == badgeWidth - 1)) {
            validMarquee = (i + j) % 4 == (aIMarquee % 4);
          } else {
            validMarquee = (i + j - 1) % 4 == (3 - (aIMarquee % 4));
          }
        }
        canvas[i][j] = canvas[i][j] || validMarquee;
      }
    }
  }
}
