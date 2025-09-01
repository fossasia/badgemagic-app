import 'dart:convert';
import 'dart:io';

import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class to store and retrieve the original text of badges
class BadgeTextStorage {
  static const String TEXT_STORAGE_FILENAME = 'badge_original_texts.json';

  /// Save the original text for a badge
  static Future<void> saveOriginalText(
      String badgeFilename, String originalText) async {
    try {
      // Get the existing text storage or create a new one
      Map<String, String> textStorage = await _getTextStorage();

      // Store the original text with the badge filename as the key
      textStorage[badgeFilename] = originalText;

      // Save the updated storage
      await _saveTextStorage(textStorage);

      logger.d('Saved original text for badge: $badgeFilename');
    } catch (e) {
      logger.e('Error saving original text: $e');
    }
  }

  /// Get the original text for a badge
  static Future<String> getOriginalText(String badgeFilename) async {
    try {
      // Get the existing text storage
      Map<String, String> textStorage = await _getTextStorage();

      // Return the original text if it exists, otherwise return empty string
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
      // Get the existing text storage
      Map<String, String> textStorage = await _getTextStorage();

      // Remove the entry for the badge
      textStorage.remove(badgeFilename);

      // Save the updated storage
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
      final file = File('${directory.path}/$TEXT_STORAGE_FILENAME');

      // Create the file if it doesn't exist
      if (!await file.exists()) {
        await file.create();
        await file.writeAsString('{}');
        return {};
      }

      // Read the file and parse the JSON
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return {};
      }

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Convert dynamic values to String
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
      final file = File('${directory.path}/$TEXT_STORAGE_FILENAME');

      // Convert the map to JSON and save it
      final jsonString = jsonEncode(textStorage);
      await file.writeAsString(jsonString);
    } catch (e) {
      logger.e('Error saving text storage: $e');
    }
  }
}
