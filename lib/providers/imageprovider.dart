import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class InlineImageProvider extends ChangeNotifier {
  // Reloads the savedBadgeCache from disk and notifies listeners
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

  //boolean variable to check for isCacheInitialized
  bool isCacheInitialized = false;

  List<MapEntry<String, Map<String, dynamic>>> savedBadgeCache = [];

  //set of available keys
  Set<int> availableKeys = {};

  bool isBackSpacePressed = false;

  void setBackSpacePressed(bool value) {
    isBackSpacePressed = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool isSavedBadgeData = false;

  //list of vectors
  List<String> vectors = [];

  //cache for storing cliparts
  Map<String, List<List<int>>?> clipartsCache = {};

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  //uses the AssetManifest class to load the list of assets
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

  //to test the delete operation in TextField
  //used for compairing the length of the current textfield and the prevous
  //if the length of the current controller length is greater than the previous (add operation)
  //else delte operation is performed.
  int controllerLength = 0;

  //object of ImageUtils class to generate ImageCache
  ImageUtils imageUtils = ImageUtils();

  //controller for the Textfield
  TextEditingController message = TextEditingController();

  /// When the multi-frame input widget is active, this is set to the
  /// [TextEditingController] of the frame that is currently focused.
  /// Clipart will be inserted into this controller instead of [message].
  TextEditingController? activeFrameController;

  /// Saves the full multi-frame text (with \f separators) when switching away
  /// from the Animation (Splitting) transition, so it can be restored.
  String? savedMultiFrameText;

  /// Remembers which frame index was active when switching away from Splitting.
  int? savedActiveFrameIndex;

  //getter for the textfield controller
  TextEditingController getController() => message;

  //selected index of the vector from the list
  late int selectedVector;

  BuildContext? context;

  void setContext(BuildContext context) {
    this.context = context;
  }

  BuildContext? get getContext => context;

  //Map to store the cache of the images generated
  //Image caches are generated at the splash screen
  //The cache generation time acts as a delay in the splash screen
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

  //function that generates the image cache
  //it fills the map with the Unit8List(byte Array) of the images
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
    // Insert into the currently focused frame if available, otherwise the
    // main message controller.
    final target = activeFrameController ?? message;
    int cursorPos =
        target.selection.baseOffset == -1 ? 0 : target.selection.baseOffset;
    String beforeCursor = target.text.substring(0, cursorPos);
    String afterCursor = target.text.substring(cursorPos);
    target.text = beforeCursor + placeholder + afterCursor;
    target.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPos + placeholder.length));
  }
}
