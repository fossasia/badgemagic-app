import 'dart:convert';
import 'dart:io';
import 'package:badgemagic/bademagic_module/utils/badge_text_storage.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    show modeValueMap;
import 'package:path_provider/path_provider.dart';

/// Helper class for loading and parsing badge data and original text from disk.
/// This class centralizes logic-heavy operations for badge editing, keeping UI code clean and testable.
class BadgeLoaderHelper {
  /// Loads badge data and original text from disk for editing.
  ///
  /// [badgeFilename] is the filename of the badge JSON (with or without .json extension).
  /// Returns a tuple: (badgeText, Data object, savedData Map).
  /// Throws if the badge file is not found or cannot be parsed.
  static Future<(String, Data, Map<String, dynamic>?)> loadBadgeDataAndText(
      String badgeFilename) async {
    Map<String, dynamic>? savedData;
    String badgeText = "";
    Data? badgeData;
    try {
      // Load badge JSON from disk. This contains all badge settings and state.
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$badgeFilename';
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        savedData = jsonDecode(jsonString) as Map<String, dynamic>;
      } else {
        // If the badge file doesn't exist, editing cannot proceed.
        throw Exception("Badge file not found: $filePath");
      }
      // Load the original badge text (the user's typed message) using BadgeTextStorage.
      // Always use .json extension for consistency with how text was saved.
      final textFilename = badgeFilename.endsWith('.json')
          ? badgeFilename
          : '$badgeFilename.json';
      badgeText = await BadgeTextStorage.getOriginalText(textFilename);
      if (badgeText.isEmpty) {
        // Fallback to default text if original is missing (should rarely happen).
        badgeText = "Hello";
      }
      // Parse the JSON map into a strongly-typed Data object for downstream use.
      badgeData = FileHelper().jsonToData(savedData);
      return (badgeText, badgeData, savedData);
    } catch (e) {
      // Rethrow so UI can handle error and show a message.
      rethrow;
    }
  }

  /// Parses the animation mode value from a badge message's mode field.
  ///
  /// Accepts either an int or an enum-like string (e.g., 'BadgeMode.left').
  /// Returns the integer mode value for use with animationMap.
  ///
  /// This logic is centralized here to allow easy extension if new modes are added.
  static int parseAnimationMode(dynamic mode) {
    if (mode is int) {
      return mode;
    }
    for (final entry in modeValueMap.entries) {
      if (entry.value == mode) {
        return entry.key;
      }
    }
    final modeString = mode.toString();
    final asInt = int.tryParse(modeString);
    if (asInt != null) {
      return asInt;
    }
    final name = modeString.contains('.')
        ? modeString.split('.').last.toLowerCase()
        : modeString.toLowerCase();
    for (final entry in modeValueMap.entries) {
      if (entry.value.name == name) {
        return entry.key;
      }
    }
    return 0;
  }
}
