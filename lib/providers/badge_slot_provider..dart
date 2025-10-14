import 'package:flutter/material.dart';

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class BadgeSlotProvider with ChangeNotifier {
  // Maps selected badge key -> selection order (0-based index)
  final Map<String, int> _badgeKeyToSelectionOrder = {};

  // Maps selected badge key -> assigned slot number (1..8) for transfer
  final Map<String, int> _badgeKeyToSlot = {};

  // Available slot numbers pool
  final Set<int> _availableSlots = {1, 2, 3, 4, 5, 6, 7, 8};

  static const int maxSelectedBadges = 8;

  Set<String> get selectedBadges => _badgeKeyToSelectionOrder.keys.toSet();

  bool isSelected(String badgeKey) =>
      _badgeKeyToSelectionOrder.containsKey(badgeKey);

  bool get canSelectMore =>
      _badgeKeyToSelectionOrder.length < maxSelectedBadges;

  int? getSlotForBadge(String badgeKey) => _badgeKeyToSlot[badgeKey];

  List<String> getSelectionsOrderedBySlot() {
    final entries = _badgeKeyToSelectionOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }

  /// ✅ Updated reorderSlots to perform push-down insertion
  void reorderSlots(String fromBadgeKey, String toBadgeKey) {
    if (!_badgeKeyToSelectionOrder.containsKey(fromBadgeKey) ||
        !_badgeKeyToSelectionOrder.containsKey(toBadgeKey)) {
      return;
    }

    final orderedKeys = getSelectionsOrderedBySlot();
    orderedKeys.remove(fromBadgeKey);
    final toIndex = orderedKeys.indexOf(toBadgeKey);

    orderedKeys.insert(toIndex, fromBadgeKey);

    // Update selection order
    _badgeKeyToSelectionOrder.clear();
    for (int i = 0; i < orderedKeys.length; i++) {
      _badgeKeyToSelectionOrder[orderedKeys[i]] = i;
    }

    // Keep original slot assignments - don't reassign slots
    // The slot numbers should remain as they were originally assigned
    notifyListeners();
  }

  void toggleSelection(String badgeKey) {
    if (_badgeKeyToSelectionOrder.containsKey(badgeKey)) {
      // Unselect: remove from selection order and slot
      _badgeKeyToSelectionOrder.remove(badgeKey);
      final freedSlot = _badgeKeyToSlot.remove(badgeKey);

      if (freedSlot != null) {
        _availableSlots.add(freedSlot);
      }

      // Don't reassign slot numbers - keep original slots for remaining badges
      notifyListeners();
      return;
    }

    if (_badgeKeyToSelectionOrder.length >= maxSelectedBadges) {
      return; // Cannot select more
    }

    // Add to selection order (append to end)
    final newOrder = _badgeKeyToSelectionOrder.length;
    _badgeKeyToSelectionOrder[badgeKey] = newOrder;

    // Assign lowest available slot number
    final smallest = _availableSlots.reduce((a, b) => a < b ? a : b);
    _availableSlots.remove(smallest);
    _badgeKeyToSlot[badgeKey] = smallest;

    notifyListeners();
  }

  void clearSelections() {
    _badgeKeyToSelectionOrder.clear();
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
