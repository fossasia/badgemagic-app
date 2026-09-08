import 'package:flutter/material.dart';

class BadgeSlotProvider with ChangeNotifier {
  final Set<String> _selectedBadges = {};
  static const int maxSelectedBadges = 8;

  Set<String> get selectedBadges => _selectedBadges;

  bool isSelected(String badgeKey) => _selectedBadges.contains(badgeKey);

  bool get canSelectMore => _selectedBadges.length < maxSelectedBadges;

  void toggleSelection(String badgeKey) {
    if (_selectedBadges.contains(badgeKey)) {
      _selectedBadges.remove(badgeKey);
      notifyListeners();
    } else if (_selectedBadges.length < maxSelectedBadges) {
      _selectedBadges.add(badgeKey);
      notifyListeners();
    }
  }

  void clearSelections() {
    _selectedBadges.clear();
    notifyListeners();
  }
}
