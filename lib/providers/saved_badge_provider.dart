import 'package:badgemagic/bademagic_module/models/data.dart';
import 'dart:convert';
import 'dart:io';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/badge_text_storage.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:get_it/get_it.dart';

Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight,
};

Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.snowflake,
  6: Mode.picture,
  7: Mode.animation,
  8: Mode.laser
};

class SavedBadgeProvider extends ChangeNotifier {
  /// Applies saved badge data to the UI providers and controllers.
  /// Moves logic out of HomeScreen._applySavedBadgeData for better separation of concerns.
  Future<void> applySavedBadgeDataToUI({
    required Map<String, dynamic> savedData,
    required String? savedBadgeFilename,
    required AnimationBadgeProvider animationProvider,
    required SpeedDialProvider speedDialProvider,
    required TextEditingController inlineimagecontroller,
    required BuildContext context,
  }) async {
    final fileHelper = FileHelper();
    // Set the text from the saved badge
    final badgeDataModel = fileHelper.jsonToData(savedData);
    final message = badgeDataModel.messages[0];

    // When we save a badge, we store the original text using BadgeTextStorage
    // Now we need to retrieve that text to show in the text field
    String badgeText = "";
    try {
      if (savedBadgeFilename != null) {
        // Get the original text from BadgeTextStorage
        badgeText = await BadgeTextStorage.getOriginalText(savedBadgeFilename);
        // If we couldn't find the original text, use the filename as a fallback
        if (badgeText.isEmpty) {
          badgeText =
              savedBadgeFilename.substring(0, savedBadgeFilename.length - 5);
          // If the filename is a timestamp, use a generic text
          if (badgeText.contains(":") && badgeText.contains("-")) {
            badgeText = "Hello"; // Default text for timestamp filenames
          }
        }
      }
    } catch (e) {
      logger.e("Failed to retrieve original badge text: $e");
      badgeText = "Hello"; // Default fallback
    }
    // Set the text in the controller
    inlineimagecontroller.text = badgeText;

    // Set animation effects
    if (message.flash) {
      animationProvider.addEffect(effectMap[1]); // Flash effect
    }
    if (message.marquee) {
      animationProvider.addEffect(effectMap[2]); // Marquee effect
    }
    // Set inversion if applicable
    if (savedData.containsKey('invert') && savedData['invert'] == true) {
      animationProvider.addEffect(effectMap[0]); // Invert effect
    }
    // Set animation mode
    int modeValue = 0; // Default to left animation
    try {
      // Handle different mode formats - could be enum or int
      if (message.mode is int) {
        modeValue = message.mode as int;
      } else {
        // Try to extract the mode value from the enum
        String modeString = message.mode.toString();
        // If it's in format "Mode.left", extract just the mode name
        if (modeString.contains('.')) {
          String modeName = modeString.split('.').last;
          // Map mode name to value
          switch (modeName.toLowerCase()) {
            case 'left':
              modeValue = 0;
              break;
            case 'right':
              modeValue = 1;
              break;
            case 'up':
              modeValue = 2;
              break;
            case 'down':
              modeValue = 3;
              break;
            case 'fixed':
              modeValue = 4;
              break;
            case 'snowflake':
              modeValue = 5;
              break;
            case 'picture':
              modeValue = 6;
              break;
            case 'animation':
              modeValue = 7;
              break;
            default:
              modeValue = 0; // Default to left
          }
        } else {
          // Try parsing as int
          modeValue = int.tryParse(modeString) ?? 0;
        }
      }
    } catch (e) {
      // If parsing fails, default to left animation (0)
      logger.e("Failed to parse mode value: $e");
    }
    animationProvider.setAnimationMode(animationMap[modeValue]);

    // Set speed using Speed.getIntValue to ensure correct dial value
    try {
      int speedDialValue = 1; // Default
      // Use the static helper method to get the correct dial value
      speedDialValue = Speed.getIntValue(message.speed);
      logger.i("Setting speed dial to: $speedDialValue from [33m");
      speedDialProvider.setDialValue(speedDialValue);
    } catch (e) {
      logger.e("Failed to set speed dial value: $e");
      speedDialProvider.setDialValue(1); // Fallback to default
    }
    // Store the filename for saving back to the same file
    setSavedBadgeDataMap(savedData);
    setIsSavedBadgeData(true);
    // Notify that we're editing an existing badge
    ToastUtils().showToast(
        "Editing badge: ${savedBadgeFilename != null ? savedBadgeFilename.substring(0, savedBadgeFilename.length - 5) : ""}");
  }

  Converters converters = Converters();
  FileHelper fileHelper = FileHelper();
  bool isSavedBadgeData = false;
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  void saveBadgeData(String filename, String message, bool isFlash,
      bool isMarquee, bool isInvert, int? speed, int animation) async {
    Data data = await getBadgeData(
      message,
      isFlash, //needs aniEffectProvider
      isMarquee,
      isInvert, //needs Anieffect provider
      speedMap[speed] ?? Speed.one, //needs speed dial provider
      modeValueMap[animation]!,
    );

    // Save the badge data to a file
    fileHelper.saveBadgeData(data, filename, isInvert);

    // Store the original text separately using BadgeTextStorage
    // This will allow us to retrieve it when editing
    await BadgeTextStorage.saveOriginalText('$filename.json', message);

    logger.d('Saved badge with original text: $message');
  }

  /// Updates an existing badge with new data
  /// This method is specifically for editing existing badges
  /// @param filename The filename of the badge to update (without .json extension)
  /// @param message The new message text for the badge
  /// @param isFlash Whether flash effect is enabled
  /// @param isMarquee Whether marquee effect is enabled
  /// @param isInvert Whether invert effect is enabled
  /// @param speed The speed value for the animation
  /// @param animation The animation mode index
  Future<void> updateBadgeData(String filename, String message, bool isFlash,
      bool isMarquee, bool isInvert, int? speed, int animation) async {
    // Make sure filename doesn't have .json extension
    String cleanFilename = filename;
    if (cleanFilename.endsWith('.json')) {
      cleanFilename = cleanFilename.substring(0, cleanFilename.length - 5);
    }

    logger.i('Updating existing badge: $cleanFilename');

    // Create the updated badge data
    Data data = await getBadgeData(
      message,
      isFlash,
      isMarquee,
      isInvert,
      speedMap[speed] ?? Speed.one,
      modeValueMap[animation]!,
    );

    try {
      // Get the document directory path using the imported path_provider package
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$cleanFilename.json';

      // First verify the file exists before trying to update it
      File file = File(filePath);
      if (await file.exists()) {
        logger.i('Found existing badge file to update: $filePath');

        // Convert Data object to JSON string
        Map<String, dynamic> jsonData = data.toJson();
        jsonData['messages'][0]['invert'] = isInvert;
        String jsonString = jsonEncode(jsonData);

        // Overwrite the existing file
        await file.writeAsString(jsonString);

        // Update the cache
        final cacheKey = '$cleanFilename.json';
        final cache = fileHelper.imageCacheProvider.savedBadgeCache;
        final existingIndex =
            cache.indexWhere((entry) => entry.key == cacheKey);

        if (existingIndex >= 0) {
          // Replace the existing entry in the cache
          logger.i('Updating existing badge in cache: $cacheKey');
          cache[existingIndex] = MapEntry(cacheKey, jsonData);
        }

        // Update the original text storage
        await BadgeTextStorage.saveOriginalText('$cleanFilename.json', message);

        logger.i('Successfully updated badge: $cleanFilename');
      } else {
        logger.e('Badge file not found for updating: $filePath');
        // If file doesn't exist, fall back to creating a new one
        fileHelper.saveBadgeData(data, cleanFilename, isInvert);
        await BadgeTextStorage.saveOriginalText('$cleanFilename.json', message);
      }
    } catch (e) {
      logger.e('Error updating badge: $e');
      // Fall back to the regular save method if there's an error
      fileHelper.saveBadgeData(data, cleanFilename, isInvert);
      await BadgeTextStorage.saveOriginalText('$cleanFilename.json', message);
    }

    logger.d('Updated badge with new text: $message');
  }

  Future<Data> getBadgeData(String text, bool flash, bool marq, bool isInverted,
      Speed speed, Mode mode) async {
    List<String> message = await converters.messageTohex(text, isInverted);
    Data data = Data(messages: [
      Message(
        text: message,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
      )
    ]);
    return data;
  }

  void savedBadgeAnimation(
      Map<String, dynamic> data, AnimationBadgeProvider aniProvider) {
    // Reset animation mode and effects to default to avoid leakage
    aniProvider.setAnimationMode(animationMap[0]); // Default to left
    aniProvider.clearAllEffects();
    //set the animations and the modes from the json file
    try {
      // Safely get the speed value
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic> &&
          data['messages'][0].containsKey('speed')) {
        // Get the speed value directly from the Speed enum without adding 1
        // The Speed.getIntValue already adds 1 to the index
        int speedValue =
            Speed.getIntValue(Speed.fromHex(data['messages'][0]['speed']));
        logger.i("Setting animation speed to: $speedValue");
        aniProvider.calculateDuration(speedValue);
      } else {
        // Default to speed 1 if data is missing
        logger.w("Missing speed data, defaulting to speed 1");
        aniProvider.calculateDuration(1);
      }
    } catch (e) {
      // Handle any errors and default to speed 1
      logger.e("Error setting animation speed: $e");
      aniProvider.calculateDuration(1);
    }
    // Safely set the animation mode
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic> &&
          data['messages'][0].containsKey('mode')) {
        int modeValue =
            Mode.getIntValue(Mode.fromHex(data['messages'][0]['mode']));
        aniProvider.setAnimationMode(animationMap[modeValue]);
      } else {
        // Default to left animation if mode is missing
        logger.w("Missing mode data, defaulting to left animation");
        aniProvider.setAnimationMode(animationMap[0]);
      }
    } catch (e) {
      // Handle any errors and default to left animation
      logger.e("Error setting animation mode: $e");
      aniProvider.setAnimationMode(animationMap[0]);
    }

    // Safely handle effects
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic>) {
        // Handle invert effect
        if (data['messages'][0].containsKey('invert') &&
            data['messages'][0]['invert'] == true) {
          aniProvider.addEffect(effectMap[0]);
        }

        // Handle flash effect
        if (data['messages'][0].containsKey('flash') &&
            data['messages'][0]['flash'] == true) {
          aniProvider.addEffect(effectMap[1]);
        }

        // Handle marquee effect
        if (data['messages'][0].containsKey('marquee') &&
            data['messages'][0]['marquee'] == true) {
          aniProvider.addEffect(effectMap[2]);
        }
      }
    } catch (e) {
      logger.e("Error setting effects: $e");
      // No default effects needed
    }

    logger.i("Effects set are = ${aniProvider.getCurrentEffect}");

    // Safely handle text data
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic> &&
          data['messages'][0].containsKey('text') &&
          data['messages'][0]['text'] is List) {
        String hexString = data['messages'][0]['text'].join();
        List<List<bool>> binaryArray = hexStringToBool(hexString);
        aniProvider.setNewGrid(binaryArray);
      } else {
        logger.w("Missing or invalid text data in badge");
        // Create a default empty grid if text data is missing
        List<List<bool>> emptyGrid =
            List.generate(8, (_) => List.generate(16, (_) => false));
        aniProvider.setNewGrid(emptyGrid);
      }
    } catch (e) {
      logger.e("Error setting badge text: $e");
      // Create a default empty grid on error
      List<List<bool>> emptyGrid =
          List.generate(8, (_) => List.generate(16, (_) => false));
      aniProvider.setNewGrid(emptyGrid);
    }
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Map<String, dynamic> savedBadgeData = {};

  void setSavedBadgeDataMap(Map<String, dynamic> data) {
    savedBadgeData = data;
    notifyListeners();
  }

  Map<String, dynamic> getSavedBadgeDataMap() => savedBadgeData;
}
