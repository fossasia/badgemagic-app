import 'package:badgemagic/models/data.dart';
import 'dart:convert';
import 'dart:io';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/storage/badge_text_storage.dart';
import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/badge_animation/ani_splitting.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
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
  5: Mode.animation,
  6: Mode.snowflake,
  7: Mode.picture,
  8: Mode.laser,
  9: Mode.pacman,
  10: Mode.chevronleft,
  11: Mode.diamond,
  12: Mode.brokenhearts,
  13: Mode.cupid,
  14: Mode.feet,
};

class SavedBadgeProvider extends ChangeNotifier {
  Future<void> applySavedBadgeDataToUI({
    required Map<String, dynamic> savedData,
    required String? savedBadgeFilename,
    required AnimationBadgeProvider animationProvider,
    required SpeedDialProvider speedDialProvider,
    required TextEditingController inlineImageController,
    required BuildContext context,
  }) async {
    final fileHelper = FileHelper();
    final badgeDataModel = fileHelper.jsonToData(savedData);
    final message = badgeDataModel.messages[0];

    String badgeText = "";
    try {
      if (savedBadgeFilename != null) {
        badgeText = await BadgeTextStorage.getOriginalText(savedBadgeFilename);
        if (badgeText.isEmpty) {
          badgeText =
              savedBadgeFilename.substring(0, savedBadgeFilename.length - 5);
          if (badgeText.contains(":") && badgeText.contains("-")) {
            badgeText = "Hello";
          }
        }
      }
    } catch (e) {
      logger.e("Failed to retrieve original badge text: $e");
      badgeText = "Hello";
    }
    inlineImageController.text = badgeText;

    if (message.flash) {
      animationProvider.addEffect(effectMap[1]);
    }
    if (message.marquee) {
      animationProvider.addEffect(effectMap[2]);
    }
    if (savedData['messages'] is List &&
        (savedData['messages'] as List).isNotEmpty &&
        savedData['messages'][0]['invert'] == true) {
      animationProvider.addEffect(effectMap[0]);
    }
    int modeValue = 0;
    modeValueMap.forEach((key, value) {
      if (value == message.mode) {
        modeValue = key;
      }
    });
    animationProvider.setAnimationMode(animationMap[modeValue]);

    try {
      int speedDialValue = 1;
      speedDialValue = Speed.getIntValue(message.speed);
      logger.i("Setting speed dial to: $speedDialValue from [33m");
      speedDialProvider.setDialValue(speedDialValue);
    } catch (e) {
      logger.e("Failed to set speed dial value: $e");
      speedDialProvider.setDialValue(1);
    }
    setSavedBadgeDataMap(savedData);
    setIsSavedBadgeData(true);
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
      isFlash,
      isMarquee,
      isInvert,
      speedMap[speed] ?? Speed.one,
      modeValueMap[animation]!,
    );

    fileHelper.saveBadgeData(data, filename, isInvert);

    await BadgeTextStorage.saveOriginalText('$filename.json', message);

    logger.d('Saved badge with original text: $message');
  }

  Future<void> updateBadgeData(String filename, String message, bool isFlash,
      bool isMarquee, bool isInvert, int? speed, int animation) async {
    String cleanFilename = filename;
    if (cleanFilename.endsWith('.json')) {
      cleanFilename = cleanFilename.substring(0, cleanFilename.length - 5);
    }

    logger.i('Updating existing badge: $cleanFilename');

    Data data = await getBadgeData(
      message,
      isFlash,
      isMarquee,
      isInvert,
      speedMap[speed] ?? Speed.one,
      modeValueMap[animation]!,
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$cleanFilename.json';

      File file = File(filePath);
      if (await file.exists()) {
        logger.i('Found existing badge file to update: $filePath');

        Map<String, dynamic> jsonData = data.toJson();
        jsonData['messages'][0]['invert'] = isInvert;
        String jsonString = jsonEncode(jsonData);

        await file.writeAsString(jsonString);

        final cacheKey = '$cleanFilename.json';
        final cache = fileHelper.imageCacheProvider.savedBadgeCache;
        final existingIndex =
            cache.indexWhere((entry) => entry.key == cacheKey);

        if (existingIndex >= 0) {
          logger.i('Updating existing badge in cache: $cacheKey');
          cache[existingIndex] = MapEntry(cacheKey, jsonData);
        }

        await BadgeTextStorage.saveOriginalText('$cleanFilename.json', message);

        logger.i('Successfully updated badge: $cleanFilename');
      } else {
        logger.e('Badge file not found for updating: $filePath');
        fileHelper.saveBadgeData(data, cleanFilename, isInvert);
        await BadgeTextStorage.saveOriginalText('$cleanFilename.json', message);
      }
    } catch (e) {
      logger.e('Error updating badge: $e');
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
    aniProvider.setAnimationMode(animationMap[0]);
    aniProvider.clearAllEffects();
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic> &&
          data['messages'][0].containsKey('speed')) {
        int speedValue =
            Speed.getIntValue(Speed.fromHex(data['messages'][0]['speed']));
        logger.i("Setting animation speed to: $speedValue");
        aniProvider.calculateDuration(speedValue);
      } else {
        logger.w("Missing speed data, defaulting to speed 1");
        aniProvider.calculateDuration(1);
      }
    } catch (e) {
      logger.e("Error setting animation speed: $e");
      aniProvider.calculateDuration(1);
    }
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic> &&
          data['messages'][0].containsKey('mode')) {
        final savedMode = Mode.fromHex(data['messages'][0]['mode']);
        int modeValue = 0;
        modeValueMap.forEach((key, value) {
          if (value == savedMode) {
            modeValue = key;
          }
        });
        aniProvider.setAnimationMode(animationMap[modeValue]);
      } else {
        logger.w("Missing mode data, defaulting to left animation");
        aniProvider.setAnimationMode(animationMap[0]);
      }
    } catch (e) {
      logger.e("Error setting animation mode: $e");
      aniProvider.setAnimationMode(animationMap[0]);
    }

    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic>) {
        if (data['messages'][0].containsKey('invert') &&
            data['messages'][0]['invert'] == true) {
          aniProvider.addEffect(effectMap[0]);
        }

        if (data['messages'][0].containsKey('flash') &&
            data['messages'][0]['flash'] == true) {
          aniProvider.addEffect(effectMap[1]);
        }

        if (data['messages'][0].containsKey('marquee') &&
            data['messages'][0]['marquee'] == true) {
          aniProvider.addEffect(effectMap[2]);
        }
      }
    } catch (e) {
      logger.e("Error setting effects: $e");
    }

    logger.i("Effects set are = ${aniProvider.getCurrentEffect}");

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
        List<List<bool>> emptyGrid =
            List.generate(8, (_) => List.generate(16, (_) => false));
        aniProvider.setNewGrid(emptyGrid);
      }
    } catch (e) {
      logger.e("Error setting badge text: $e");
      List<List<bool>> emptyGrid =
          List.generate(8, (_) => List.generate(16, (_) => false));
      aniProvider.setNewGrid(emptyGrid);
    }
  }

  void updateSelectionPreview(
    Set<String> selectedKeys,
    List<MapEntry<String, Map<String, dynamic>>> cache,
    AnimationBadgeProvider aniProvider,
  ) {
    final selected = selectedKeys
        .map((key) {
          final match = cache.where((entry) => entry.key == key).toList();
          return match.isEmpty ? null : match.first.value;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (selected.isEmpty) {
      aniProvider.stopAllAnimations();
      aniProvider.setNewGrid(
          List.generate(11, (_) => List.generate(44, (_) => false)));
      return;
    }

    if (selected.length == 1) {
      savedBadgeAnimation(selected.first, aniProvider);
      return;
    }

    aniProvider.clearAllEffects();
    aniProvider.setAnimationMode(SplittingAnimation());
    final previewGrid = List.generate(11, (_) => <bool>[]);
    for (final badge in selected) {
      try {
        final text = (badge['messages'][0]['text'] as List).join();
        if (text.isEmpty) continue;
        final grid = hexStringToBool(text);
        for (int r = 0; r < 11 && r < grid.length; r++) {
          if (previewGrid[r].isNotEmpty) {
            previewGrid[r].addAll(List.filled(8, false));
          }
          previewGrid[r].addAll(grid[r]);
        }
      } catch (e) {
        logger.e('Failed to decode saved badge for preview: $e');
      }
    }
    aniProvider.setNewGrid(previewGrid);
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Map<String, dynamic> savedBadgeData = {};

  void setSavedBadgeDataMap(Map<String, dynamic> data) {
    savedBadgeData = data;
    notifyListeners();
  }

  Map<String, dynamic> getSavedBadgeDataMap() => savedBadgeData;

  Future<bool> showEditBadgeConfirmation(BuildContext context) async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editBadge),
        content: Text(l10n.editBadgeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
