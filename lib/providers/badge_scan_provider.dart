import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BadgeScanMode { any, specific }

class BadgeScanProvider with ChangeNotifier {
  BadgeScanMode _mode = BadgeScanMode.any;
  List<String> _badgeNames = ['LSLED', 'VBLAB'];
  Set<int> _selectedIndices = {}; // Track selected badge indices
  bool _isLoaded = false;

  BadgeScanMode get mode => _mode;
  List<String> get badgeNames => List.unmodifiable(_badgeNames);
  Set<int> get selectedIndices => Set.unmodifiable(_selectedIndices);
  bool get isLoaded => _isLoaded;

  BadgeScanProvider() {
    _loadFromPrefs(); // Load persisted values in background
  }

  // --- Persistence helpers ---
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load scan mode
    final modeIndex = prefs.getInt('badge_scan_mode');
    if (modeIndex != null) {
      _mode = BadgeScanMode.values[modeIndex];
    }

    // Load badge names
    final storedNames = prefs.getStringList('badge_names');
    if (storedNames != null && storedNames.isNotEmpty) {
      _badgeNames = storedNames;
    }

    _isLoaded = true;
    notifyListeners(); // Notify UI that values are loaded
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badge_scan_mode', _mode.index);
    await prefs.setStringList('badge_names', _badgeNames);
  }

  // --- Public methods to update values ---
  void setMode(BadgeScanMode mode) {
    _mode = mode;
    _saveToPrefs();
    notifyListeners();
  }

  void setBadgeNames(List<String> names) {
    _badgeNames = names.where((name) => name.trim().isNotEmpty).toList();
    _selectedIndices.clear(); // Clear selections when badge names change
    _saveToPrefs();
    notifyListeners();
  }

  void addBadgeName(String name) {
    if (name.trim().isEmpty) return;
    _badgeNames.add(name.trim());
    _saveToPrefs();
    notifyListeners();
  }

  void removeBadgeNameAt(int index) {
    if (index < 0 || index >= _badgeNames.length) return;
    _badgeNames.removeAt(index);

    // Update selected indices after removal
    _selectedIndices.removeWhere((i) => i == index);
    _selectedIndices =
        _selectedIndices.map((i) => i > index ? i - 1 : i).toSet();

    _saveToPrefs();
    notifyListeners();
  }

  void updateBadgeName(int index, String newName) {
    if (index < 0 || index >= _badgeNames.length) return;
    _badgeNames[index] = newName.trim();
    _saveToPrefs();
    notifyListeners();
  }

  // --- Selection methods ---
  void toggleSelection(int index) {
    if (index < 0 || index >= _badgeNames.length) return;

    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  bool isSelected(int index) {
    return _selectedIndices.contains(index);
  }

  void clearSelection() {
    _selectedIndices.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedIndices =
        Set.from(List.generate(_badgeNames.length, (index) => index));
    notifyListeners();
  }

  void removeSelectedDevices() {
    if (_selectedIndices.isEmpty) return;

    // Sort indices in descending order to remove from end first
    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < _badgeNames.length) {
        _badgeNames.removeAt(index);
      }
    }

    _selectedIndices.clear();
    _saveToPrefs();
    notifyListeners();
  }

  List<String> getSelectedBadgeNames() {
    return _selectedIndices
        .where((index) => index < _badgeNames.length)
        .map((index) => _badgeNames[index])
        .toList();
  }
}
