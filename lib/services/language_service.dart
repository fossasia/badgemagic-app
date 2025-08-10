import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String defaultLanguage = 'en';

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? defaultLanguage;
  }

  static Locale getLocale(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
}
