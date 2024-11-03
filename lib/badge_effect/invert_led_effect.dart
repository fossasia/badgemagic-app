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
      int badgeHeight, int badgeWidth) {}
}
