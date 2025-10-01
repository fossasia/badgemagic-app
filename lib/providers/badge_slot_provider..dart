import 'package:flutter/material.dart';

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class BadgeSlotProvider with ChangeNotifier {
  // Maps selected badge key -> assigned slot number (1..8)
  final Map<String, int> _badgeKeyToSlot = {};

  // Available slot numbers pool
  final Set<int> _availableSlots = {1, 2, 3, 4, 5, 6, 7, 8};

  static const int maxSelectedBadges = 8;

  Set<String> get selectedBadges => _badgeKeyToSlot.keys.toSet();

  bool isSelected(String badgeKey) => _badgeKeyToSlot.containsKey(badgeKey);

  bool get canSelectMore =>
      _badgeKeyToSlot.length < maxSelectedBadges && _availableSlots.isNotEmpty;

  int? getSlotForBadge(String badgeKey) => _badgeKeyToSlot[badgeKey];

  List<String> getSelectionsOrderedBySlot() {
    final entries = _badgeKeyToSlot.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }

  /// ✅ Updated reorderSlots to perform push-down insertion
  void reorderSlots(String fromBadgeKey, String toBadgeKey) {
    if (!_badgeKeyToSlot.containsKey(fromBadgeKey) ||
        !_badgeKeyToSlot.containsKey(toBadgeKey)) return;

    final orderedKeys = getSelectionsOrderedBySlot();
    orderedKeys.remove(fromBadgeKey);
    final toIndex = orderedKeys.indexOf(toBadgeKey);

    orderedKeys.insert(toIndex, fromBadgeKey);

    _badgeKeyToSlot.clear();
    _availableSlots
      ..clear()
      ..addAll({1, 2, 3, 4, 5, 6, 7, 8});

    for (int i = 0; i < orderedKeys.length; i++) {
      final slot = i + 1;
      _badgeKeyToSlot[orderedKeys[i]] = slot;
      _availableSlots.remove(slot);
    }

    notifyListeners();
  }

  void toggleSelection(String badgeKey) {
    if (_badgeKeyToSlot.containsKey(badgeKey)) {
      // Unselect: free its slot
      final freedSlot = _badgeKeyToSlot.remove(badgeKey);
      if (freedSlot != null) {
        _availableSlots.add(freedSlot);
      }
      notifyListeners();
      return;
    }

    if (_badgeKeyToSlot.length >= maxSelectedBadges ||
        _availableSlots.isEmpty) {
      return; // Cannot select more
    }

    // Assign smallest available slot
    final smallest = _availableSlots.reduce((a, b) => a < b ? a : b);
    _availableSlots.remove(smallest);
    _badgeKeyToSlot[badgeKey] = smallest;
    notifyListeners();
  }

  void clearSelections() {
    _badgeKeyToSlot.clear();
    _availableSlots
      ..clear()
      ..addAll({1, 2, 3, 4, 5, 6, 7, 8});
    notifyListeners();
  }

  bool canTransfer(String badgeKey) {
    final slot = _badgeKeyToSlot[badgeKey];
    return slot != null && slot <= 8;
  }

  List<String> getTransferableBadges() {
    return getSelectionsOrderedBySlot().take(8).toList();
  }
}
