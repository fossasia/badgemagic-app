import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class InlineImageProvider extends ChangeNotifier {
  Future<void> reloadSavedBadgeCache() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final badgeFiles = files
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.json') &&
            !file.path.endsWith('badge_original_texts.json'))
        .toList();
    List<MapEntry<String, Map<String, dynamic>>> badgeList = [];
    for (final file in badgeFiles) {
      final contents = await file.readAsString();
      try {
        final data = json.decode(contents) as Map<String, dynamic>;
        badgeList.add(MapEntry(file.uri.pathSegments.last, data));
      } catch (_) {}
    }
    savedBadgeCache = badgeList;
    notifyListeners();
  }

  bool isCacheInitialized = false;

  List<MapEntry<String, Map<String, dynamic>>> savedBadgeCache = [];

  Set<int> availableKeys = {};

  bool isBackSpacePressed = false;

  void setBackSpacePressed(bool value) {
    isBackSpacePressed = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool isSavedBadgeData = false;

  List<String> vectors = [];

  Map<String, List<List<int>>?> clipartsCache = {};

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Future<void> initVectors() async {
    vectors.clear();
    try {
      final manifestContent =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final vectorAssets = manifestContent
          .listAssets()
          .where((key) => key.startsWith('assets/vectors/'))
          .toList();
      vectors.addAll(vectorAssets);
      notifyListeners();
    } catch (e) {
      logger.e('Error loading asset manifest: $e');
    }
  }

  int controllerLength = 0;

  ImageUtils imageUtils = ImageUtils();

  TextEditingController message = TextEditingController();

  TextEditingController getController() => message;

  late int selectedVector;

  BuildContext? context;

  void setContext(BuildContext context) {
    this.context = context;
  }

  BuildContext? get getContext => context;

  Map<Object, Uint8List?> imageCache = {};

  void notify() {
    notifyListeners();
  }

  void removeFromCache(String filename) {
    imageCache.removeWhere(
      (key, value) => key is List && key.isNotEmpty && key[0] == filename,
    );
    logger.d('Removed from cache: $filename');
    notifyListeners();
  }

  Future<void> generateImageCache() async {
    imageCache.clear();
    FileHelper fileHelper = FileHelper();
    await initVectors();
    for (int x = 0; x < vectors.length; x++) {
      ui.Image image = await imageUtils.generateImageView(vectors[x]);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var unit8List = byteData!.buffer.asUint8List();
      imageCache[x] = unit8List;
    }
    await fileHelper.loadImageCacheFromFiles();
    notifyListeners();
  }

  void insertInlineImage(Object key) {
    int index = 0;
    if (key is int) {
      index = key;
    } else if (key is List) {
      index = key[1];
    }
    logger.d('Inserting image at index: $index');
    String placeholder = index < 10 ? '<<0$index>>' : '<<$index>>';
    int cursorPos =
        message.selection.baseOffset == -1 ? 0 : message.selection.baseOffset;
    String beforeCursor = message.text.substring(0, cursorPos);
    String afterCursor = message.text.substring(cursorPos);
    message.text = beforeCursor + placeholder + afterCursor;
    message.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPos + placeholder.length));
  }
}
