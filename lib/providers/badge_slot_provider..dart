import 'package:flutter/material.dart';

class BadgeSlotProvider extends ChangeNotifier {
  List<MapEntry<String, Map<String, dynamic>>> orderedBadges = [];
  bool _isInitialized = false;

  void initialize(List<MapEntry<String, Map<String, dynamic>>> initialBadges) {
    if (!_isInitialized || orderedBadges.length != initialBadges.length) {
      orderedBadges = initialBadges
          .where((entry) => entry.key != 'badge_original_texts.json')
          .toList();
      _isInitialized = true;
    }
  }

  void reorderBadges(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = orderedBadges.removeAt(oldIndex);
    orderedBadges.insert(newIndex, item);
    notifyListeners();
  }

  void removeBadge(String key) {
    orderedBadges.removeWhere((element) => element.key == key);
    notifyListeners();
  }

  void clearAll() {
    orderedBadges.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
