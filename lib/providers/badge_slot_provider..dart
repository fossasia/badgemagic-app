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

  /// Get the slot number for a badge based on its position in the first 8 items
  /// This is for display purposes (showing 1-8 on the first 8 badges)
  int? getPositionSlotForBadge(String badgeKey, int positionInList) {
    // First 8 positions get slot numbers 1-8
    if (positionInList < 8) {
      return positionInList + 1;
    }
    return null;
  }

  List<String> getSelectionsOrderedBySlot() {
    final entries = _badgeKeyToSelectionOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }

  /// Swaps visual positions between two badges when drag and drop occurs
  /// Also swaps selection state when one badge is selected and the other is not
  void reorderSlots(
      String fromBadgeKey, String toBadgeKey, int fromIndex, int toIndex) {
    final isFromSelected = _badgeKeyToSelectionOrder.containsKey(fromBadgeKey);
    final isToSelected = _badgeKeyToSelectionOrder.containsKey(toBadgeKey);

    // Swap selection states if one is selected and the other is not
    if (isFromSelected && !isToSelected) {
      // Case 1: Dragging a selected badge onto an unselected badge
      // Swap selection states: unselect fromBadgeKey, select toBadgeKey

      // Get the slot number and selection order from fromBadgeKey
      final slotNumber = _badgeKeyToSlot[fromBadgeKey];
      final selectionOrder = _badgeKeyToSelectionOrder[fromBadgeKey];

      // Remove fromBadgeKey from selection
      _badgeKeyToSelectionOrder.remove(fromBadgeKey);
      if (slotNumber != null) {
        _badgeKeyToSlot.remove(fromBadgeKey);
        _availableSlots.add(slotNumber);
      }

      // Select toBadgeKey with the freed slot
      if (slotNumber != null) {
        _availableSlots.remove(slotNumber);
        _badgeKeyToSlot[toBadgeKey] = slotNumber;
        _badgeKeyToSelectionOrder[toBadgeKey] = selectionOrder!;
      }
    } else if (!isFromSelected && isToSelected) {
      // Case 2: Dragging an unselected badge onto a selected badge
      // Swap selection states: select fromBadgeKey, unselect toBadgeKey

      // Get the slot number and selection order from toBadgeKey
      final slotNumber = _badgeKeyToSlot[toBadgeKey];
      final selectionOrder = _badgeKeyToSelectionOrder[toBadgeKey];

      // Remove toBadgeKey from selection
      _badgeKeyToSelectionOrder.remove(toBadgeKey);
      if (slotNumber != null) {
        _badgeKeyToSlot.remove(toBadgeKey);
        _availableSlots.add(slotNumber);
      }

      // Select fromBadgeKey with the freed slot
      if (slotNumber != null) {
        _availableSlots.remove(slotNumber);
        _badgeKeyToSlot[fromBadgeKey] = slotNumber;
        _badgeKeyToSelectionOrder[fromBadgeKey] = selectionOrder!;
      }
    }

    // Assign visual order if badges don't have one
    // Use current index as fallback for visual order
    if (!_badgeKeyToVisualOrder.containsKey(fromBadgeKey)) {
      _badgeKeyToVisualOrder[fromBadgeKey] = fromIndex;
    }
    if (!_badgeKeyToVisualOrder.containsKey(toBadgeKey)) {
      _badgeKeyToVisualOrder[toBadgeKey] = toIndex;
    }

    // Now swap the visual order values
    final fromVisual = _badgeKeyToVisualOrder[fromBadgeKey]!;
    final toVisual = _badgeKeyToVisualOrder[toBadgeKey]!;

    _badgeKeyToVisualOrder[fromBadgeKey] = toVisual;
    _badgeKeyToVisualOrder[toBadgeKey] = fromVisual;

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
