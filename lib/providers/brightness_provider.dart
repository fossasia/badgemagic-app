import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:flutter/material.dart';

class BrightnessProvider extends ChangeNotifier {
  Brightness _brightness = Brightness.hundred;

  Brightness getBrightness() => _brightness;

  void setBrightness(Brightness brightness) {
    _brightness = brightness;
    notifyListeners();
  }

  int getBrightnessPercentage() => _brightness.percentage;
}
