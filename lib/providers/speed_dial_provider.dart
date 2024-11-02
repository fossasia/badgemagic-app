import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:flutter/material.dart';

class SpeedDialProvider extends ChangeNotifier {
  AnimationBadgeProvider? badgeProvider;
  int outerValue = 1;

  int getOuterValue() => outerValue;

  void setDialValue(int value) {
    badgeProvider?.calculateDuration(value);
    outerValue = value;
    notifyListeners();
  }

  SpeedDialProvider(AnimationBadgeProvider provider) {
    badgeProvider = provider;
    notifyListeners();
    logger.i("Badge Provider set for SpeedDialProvider");
  }
}
