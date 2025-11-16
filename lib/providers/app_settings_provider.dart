import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScreenSize { S, M, L, XL }

class AppSettingsProvider with ChangeNotifier {
  bool enableScreens = false;
  ScreenSize selectedSize = ScreenSize.S;
  bool enableStreams = false;

  AppSettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    enableScreens = prefs.getBool('enableScreens') ?? false;
    enableStreams = prefs.getBool('enableStreams') ?? false;
    final sizeName = prefs.getString('selectedSize') ?? ScreenSize.S.name;
    selectedSize = ScreenSize.values.byName(sizeName);

    notifyListeners();
  }

  void _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enableScreens', enableScreens);
    prefs.setBool('enableStreams', enableStreams);
    prefs.setString('selectedSize', selectedSize.name);
  }

  void toggleScreens(bool value) {
    enableScreens = value;
    if (!value) selectedSize = ScreenSize.S;
    _saveToPrefs();
    notifyListeners();
  }

  void setSize(ScreenSize size) {
    selectedSize = size;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleStreams(bool value) {
    enableStreams = value;
    _saveToPrefs();
    notifyListeners();
  }
}
