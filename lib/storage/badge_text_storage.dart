import 'dart:convert';
import 'dart:io';

import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class to store and retrieve the original text of badges
class BadgeTextStorage {
  static const String _textStorageFileName = 'badge_original_texts.json';

  /// Save the original text for a badge
  static Future<void> saveOriginalText(
      String badgeFilename, String originalText) async {
    try {
      Map<String, String> textStorage = await _getTextStorage();

      textStorage[badgeFilename] = originalText;

      await _saveTextStorage(textStorage);

      logger.d('Saved original text for badge: $badgeFilename');
    } catch (e) {
      logger.e('Error saving original text: $e');
    }
  }

  /// Get the original text for a badge
  static Future<String> getOriginalText(String badgeFilename) async {
    try {
      Map<String, String> textStorage = await _getTextStorage();

      return textStorage[badgeFilename] ?? '';
    } catch (e) {
      logger.e('Error getting original text: $e');
      return '';
    }
  }

  /// Move the original text mapping from oldFilename to newFilename
  static Future<void> moveOriginalText(
      String oldFilename, String newFilename) async {
    try {
      Map<String, String> textStorage = await _getTextStorage();
      if (textStorage.containsKey(oldFilename)) {
        textStorage[newFilename] = textStorage[oldFilename]!;
        textStorage.remove(oldFilename);
        await _saveTextStorage(textStorage);
        logger.d('Moved original text from: $oldFilename to $newFilename');
      }
    } catch (e) {
      logger.e('Error moving original text: $e');
    }
  }

  /// Delete the original text for a badge
  static Future<void> deleteOriginalText(String badgeFilename) async {
    try {
      Map<String, String> textStorage = await _getTextStorage();

      textStorage.remove(badgeFilename);

      await _saveTextStorage(textStorage);

      logger.d('Deleted original text for badge: $badgeFilename');
    } catch (e) {
      logger.e('Error deleting original text: $e');
    }
  }

  /// Get the text storage file
  static Future<Map<String, String>> _getTextStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_textStorageFileName');

      if (!await file.exists()) {
        await file.create();
        await file.writeAsString('{}');
        return {};
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return {};
      }

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      final Map<String, String> textStorage = {};
      jsonData.forEach((key, value) {
        textStorage[key] = value.toString();
      });

      return textStorage;
    } catch (e) {
      logger.e('Error getting text storage: $e');
      return {};
    }
  }

  /// Save the text storage to file
  static Future<void> _saveTextStorage(Map<String, String> textStorage) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_textStorageFileName');

      final jsonString = jsonEncode(textStorage);
      await file.writeAsString(jsonString);
    } catch (e) {
      logger.e('Error saving text storage: $e');
    }
  }
}
