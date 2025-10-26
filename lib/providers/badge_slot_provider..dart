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

  // Maps badge key -> visual order in the list (for display)
  // Visual order represents the target position where badge should appear
  final Map<String, int> _badgeKeyToVisualOrder = {};

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

  /// Swaps slot assignments between two badges when drag and drop occurs
  void reorderSlots(String fromBadgeKey, String toBadgeKey) {
    if (!_badgeKeyToSelectionOrder.containsKey(fromBadgeKey) ||
        !_badgeKeyToSelectionOrder.containsKey(toBadgeKey)) {
      return;
    }

    // Swap the slot assignments
    final fromSlot = _badgeKeyToSlot[fromBadgeKey];
    final toSlot = _badgeKeyToSlot[toBadgeKey];

    if (fromSlot != null && toSlot != null) {
      _badgeKeyToSlot[fromBadgeKey] = toSlot;
      _badgeKeyToSlot[toBadgeKey] = fromSlot;
    }

    // Swap the visual order assignments
    final fromVisual = _badgeKeyToVisualOrder[fromBadgeKey];
    final toVisual = _badgeKeyToVisualOrder[toBadgeKey];

    if (fromVisual != null && toVisual != null) {
      // Both have visual order, swap them
      _badgeKeyToVisualOrder[fromBadgeKey] = toVisual;
      _badgeKeyToVisualOrder[toBadgeKey] = fromVisual;
    } else if (fromVisual == null && toVisual == null) {
      // Neither has visual order, assign them based on slots after swap
      // Use the swapped slot numbers as visual order
      if (fromSlot != null && toSlot != null) {
        _badgeKeyToVisualOrder[fromBadgeKey] = toSlot;
        _badgeKeyToVisualOrder[toBadgeKey] = fromSlot;
      }
    } else if (fromVisual == null) {
      // fromBadgeKey doesn't have visual order yet
      if (toSlot != null) {
        _badgeKeyToVisualOrder[fromBadgeKey] = toSlot;
      }
      if (toVisual != null && fromSlot != null) {
        _badgeKeyToVisualOrder[toBadgeKey] = fromSlot;
      } else if (fromSlot != null) {
        _badgeKeyToVisualOrder[toBadgeKey] = fromSlot;
      }
    } else {
      // toBadgeKey doesn't have visual order yet
      if (fromSlot != null && toSlot != null) {
        _badgeKeyToVisualOrder[fromBadgeKey] = toSlot;
        _badgeKeyToVisualOrder[toBadgeKey] = fromSlot;
      }
    }

    // Update selection order to reflect the slot positions
    // Sort badges by their slot numbers (1, 2, 3, etc.)
    final allBadgeKeys = _badgeKeyToSlot.keys.toList();
    allBadgeKeys.sort((a, b) {
      final slotA = _badgeKeyToSlot[a] ?? 0;
      final slotB = _badgeKeyToSlot[b] ?? 0;
      return slotA.compareTo(slotB);
    });

    // Reassign selection order based on sorted slot positions
    _badgeKeyToSelectionOrder.clear();
    for (int i = 0; i < allBadgeKeys.length; i++) {
      _badgeKeyToSelectionOrder[allBadgeKeys[i]] = i;
    }

    notifyListeners();
  }

  void toggleSelection(String badgeKey) {
    if (_badgeKeyToSelectionOrder.containsKey(badgeKey)) {
      // Unselect: remove from selection order but keep original slot and visual order assignments
      _badgeKeyToSelectionOrder.remove(badgeKey);
      // CRITICAL: Keep visual order so badge doesn't move in the list when deselected
      // _badgeKeyToVisualOrder stays intact
      final freedSlot = _badgeKeyToSlot.remove(badgeKey);

      // Add the freed slot to available slots
      if (freedSlot != null) {
        _availableSlots.add(freedSlot);
      }

      // CRITICAL: Do NOT reindex the remaining badges
      // This keeps A (slot 1), C (slot 3) in their original positions
      // even after B (slot 2) is deselected

      notifyListeners();
      return;
    }

    if (_badgeKeyToSelectionOrder.length >= maxSelectedBadges) {
      return; // Cannot select more
    }

    // Add to selection order (append to end)
    final newOrder = _badgeKeyToSelectionOrder.length;
    _badgeKeyToSelectionOrder[badgeKey] = newOrder;

    // CRITICAL: Do NOT assign visual order on selection
    // Visual order is only assigned when badges are swapped via drag-and-drop
    // This keeps selected badges in their original file position

    // Assign lowest available slot number
    final smallest = _availableSlots.reduce((a, b) => a < b ? a : b);
    _availableSlots.remove(smallest);
    _badgeKeyToSlot[badgeKey] = smallest;

    notifyListeners();
  }

  void clearSelections() {
    _badgeKeyToSelectionOrder.clear();
    _badgeKeyToSlot.clear();
    _badgeKeyToVisualOrder.clear();
    _availableSlots
      ..clear()
      ..addAll({1, 2, 3, 4, 5, 6, 7, 8});
    notifyListeners();
  }

  int? getVisualOrder(String badgeKey) => _badgeKeyToVisualOrder[badgeKey];

  bool canTransfer(String badgeKey) {
    final slot = _badgeKeyToSlot[badgeKey];
    return slot != null && slot <= 8;
  }

  List<String> getTransferableBadges() {
    return getSelectionsOrderedBySlot().take(8).toList();
  }
}
