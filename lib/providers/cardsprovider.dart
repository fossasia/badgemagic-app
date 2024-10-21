import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/badgeview_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class CardProvider extends ChangeNotifier {
  DrawBadgeProvider badgeViewProvider = GetIt.instance<DrawBadgeProvider>();
  InlineImageProvider imageProvider = GetIt.instance<InlineImageProvider>();
  ImageUtils imageUtils = ImageUtils();
  int outerValue = 1;
  List<int> effectsIndex = [0, 0, 0];
  int animationIndex = 0;

  //used for tranfer logic to find wether the.
  //the transfer is from the jason or not.
  bool isSavedBadgeData = false;

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Map<String, dynamic> savedBadgeData = {};

  void setSavedBadgeDataMap(Map<String, dynamic> data) {
    savedBadgeData = data;
    notifyListeners();
  }

  Map<String, dynamic> getSavedBadgeDataMap() => savedBadgeData;

  int getOuterValue() => outerValue;

  //context for snackbar
  BuildContext? context;

  void setContext(BuildContext context) {
    this.context = context;
    notifyListeners();
  }

  BuildContext? getContext() => context;

  //outer value for the speed dial
  void setOuterValue(int value) {
    badgeViewProvider.calculateDuration(value);
    outerValue = value;
    notifyListeners();
  }

  int getAnimationIndex() => animationIndex;

  int getEffectIndex(int index) => effectsIndex[index];

  void setAnimationIndex(int index) {
    badgeViewProvider.setAnimationMode(index);
    animationIndex = index;
    notifyListeners();
  }

  void setEffectIndex(int index) {
    effectsIndex[index] = effectsIndex[index] == 1 ? 0 : 1;
    badgeViewProvider.setEffectIndex(effectsIndex);
    notifyListeners();
  }
}
