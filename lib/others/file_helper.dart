import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/others/badge_text_storage.dart';
import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class FileHelper {
  final InlineImageProvider imageCacheProvider =
      GetIt.instance<InlineImageProvider>();
  ImageUtils imageUtils = ImageUtils();
  static const Uuid uuid = Uuid();

  static Future<String> _getFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  static Future<File> _writeToFile(String filename, String data) async {
    final path = await _getFilePath(filename);
    logger.d('Writing to file: $path');
    return File(path).writeAsString(data);
  }

  static String _generateUniqueFilename() {
    final String uniqueId = uuid.v4();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'data_${timestamp}_$uniqueId.json';
  }

  void addToCache(Uint8List imageData, String filename) {
    int key;
    if (imageCacheProvider.availableKeys.isNotEmpty) {
      key = imageCacheProvider.availableKeys.first;
      imageCacheProvider.availableKeys.remove(key);
    } else {
      key = imageCacheProvider.imageCache.length;
      while (imageCacheProvider.imageCache.containsKey(key)) {
        key++;
      }
    }

    imageCacheProvider.imageCache[[filename, key]] = imageData;
    imageCacheProvider.notify();
  }

  Future<void> generateClipartCache() async {
    imageCacheProvider.clipartsCache = {};
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    for (var file in files) {
      if (file is File &&
          file.path.endsWith('.json') &&
          file.path.contains('data_')) {
        try {
          Uint8List fileBytes = await file.readAsBytes();
          String content = utf8.decode(fileBytes);

          if (content.isNotEmpty) {
            final List<dynamic> decodedData = jsonDecode(content);
            final List<List<dynamic>> imageData =
                decodedData.cast<List<dynamic>>();
            List<List<int>> intImageData =
                imageData.map((list) => list.cast<int>()).toList();
            imageCacheProvider.clipartsCache[file.uri.pathSegments.last] =
                intImageData;
          }
        } catch (e) {
          logger.i('Error reading or decoding the file: $e');
        }
      }
    }
  }

  void removeFromCache(int key) {
    if (imageCacheProvider.imageCache.containsKey(key)) {
      imageCacheProvider.imageCache.remove(key);
      imageCacheProvider.availableKeys.add(key);
    }
  }

  Future<void> _addImageDataToCache(
      List<List<dynamic>> imageData, String filename) async {
    List<List<int>> intImageData =
        imageData.map((list) => list.cast<int>()).toList();
    Uint8List imageBytes =
        await imageUtils.convert2DListToUint8List(intImageData);
    addToCache(imageBytes, filename);
  }

  static List<List<int>> trimEmptyPadding(List<List<int>> image) {
    if (image.isEmpty || image[0].isEmpty) return const [];

    final int rows = image.length;
    final int cols = image[0].length;
    int left = cols, right = -1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (image[r][c] != 0) {
          if (c < left) left = c;
          if (c > right) right = c;
        }
      }
    }

    if (right < 0) return const [];

    return List.generate(
      rows,
      (i) => image[i].sublist(left, right + 1),
    );
  }

  static const int _badgeRows = 11;
  static List<List<int>> normalizeClipartHeight(List<List<int>> image) {
    if (image.isEmpty) return image;
    final int cols = image[0].length;
    if (image.length == _badgeRows) return image;

    if (image.length < _badgeRows) {
      final int missing = _badgeRows - image.length;
      final int top = missing ~/ 2;
      final int bottom = missing - top;
      return [
        for (int i = 0; i < top; i++) List<int>.filled(cols, 0),
        ...image,
        for (int i = 0; i < bottom; i++) List<int>.filled(cols, 0),
      ];
    }

    return image.sublist(0, _badgeRows);
  }

  static List<List<int>> addClipartSideMargins(List<List<int>> image) {
    if (image.isEmpty) return image;
    return [
      for (final row in image) <int>[0, ...row, 0],
    ];
  }

  Future<bool> updateClipart(String filename, List<List<int>> image) async {
    final List<List<int>> trimmed = trimEmptyPadding(image);
    if (trimmed.isEmpty) {
      logger.i('Skipping save: clipart is empty after trimming');
      return false;
    }

    logger.d('Updating clipart: $filename');
    String jsonData = jsonEncode(trimmed);

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    logger.d('File path: $filePath');

    final file = File(filePath);

    if (await file.exists()) {
      logger.d('File found: $filename');
      await file.writeAsString(jsonData);
      logger.d('File content updated: $filename');
    } else {
      await file.create(recursive: true);
      await file.writeAsString(jsonData);
      logger.d('New file created and content written: $filename');
    }
    return true;
  }

  Future<void> loadImageCacheFromFiles() async {
    await generateClipartCache();
    await getBadgeDataFiles();
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();

    files.sort((a, b) {
      if (a is File && b is File) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      }
      return 0;
    });

    for (var file in files) {
      if (file is File &&
          file.path.endsWith('.json') &&
          file.path.contains('data_')) {
        final String content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> decodedData = jsonDecode(content);
          final List<List<dynamic>> imageData =
              decodedData.cast<List<dynamic>>();
          await _addImageDataToCache(imageData, file.uri.pathSegments.last);
        }
      }
    }
  }

  Future<bool> saveImage(List<List<bool>> imageData) async {
    List<List<int>> image = List.generate(
        imageData.length, (i) => List<int>.filled(imageData[i].length, 0));

    for (int i = 0; i < imageData.length; i++) {
      for (int j = 0; j < imageData[i].length; j++) {
        image[i][j] = imageData[i][j] ? 1 : 0;
      }
    }

    final List<List<int>> trimmed = trimEmptyPadding(image);
    if (trimmed.isEmpty) {
      logger.i('Skipping save: clipart is empty');
      return false;
    }

    String filename = _generateUniqueFilename();

    logger.d('Saving image to file: $filename');

    String jsonData = jsonEncode(trimmed);

    logger.d('JSON data: $jsonData');

    await _writeToFile(filename, jsonData);

    logger.d('Image saved to file: $filename');

    await _addImageDataToCache(trimmed, filename);
    return true;
  }

  Future<dynamic> readFromFile(String filename) async {
    try {
      final path = await _getFilePath(filename);
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      } else {
        logger.i('File not found: $path');
        return null;
      }
    } catch (e) {
      logger.i('Error reading from file: $e');
      return null;
    }
  }

  Future<void> updateBadgeText(String filename, List<String> newText) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      File file = File(filePath);
      if (await file.exists()) {
        String jsonString = await file.readAsString();

        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        if (jsonData.containsKey('messages') && jsonData['messages'] is List) {
          List<dynamic> messages = jsonData['messages'];

          if (messages.isNotEmpty && messages[0] is Map<String, dynamic>) {
            Map<String, dynamic> message = messages[0];

            message['text'] = newText;

            String updatedJsonString = jsonEncode(jsonData);

            await file.writeAsString(updatedJsonString, mode: FileMode.write);
            logger.i('Text field updated in $filePath');
            await getBadgeDataFiles();
          } else {
            logger.i('No message found to update.');
          }
        } else {
          logger.i('Invalid JSON structure: No messages found.');
        }
      } else {
        logger.i('File not found: $filePath');
      }
    } catch (e) {
      logger.i('Error updating text: $e');
    }
  }

  Future<void> saveBadgeData(Data data, String filename, bool invert) async {
    try {
      Map<String, dynamic> jsonData = data.toJson();
      jsonData['messages'][0]['invert'] = invert;
      logger.d('JSON data: $jsonData');
      String jsonString = jsonEncode(jsonData);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename.json';

      File file = File(filePath);
      await file.writeAsString(jsonString);

      _updateSavedBadgeCache(filename, jsonData);

      logger.i('Data saved to $filePath');
    } catch (e) {
      logger.i('Error saving data: $e');
    }
  }

  void _updateSavedBadgeCache(String filename, Map<String, dynamic> jsonData) {
    final cacheKey = "$filename.json";
    final cache = imageCacheProvider.savedBadgeCache;
    final existingIndex = cache.indexWhere((entry) => entry.key == cacheKey);
    if (existingIndex >= 0) {
      logger.i('Updating existing badge in cache: $cacheKey');
      cache[existingIndex] = MapEntry(cacheKey, jsonData);
    } else {
      logger.i('Adding new badge to cache: $cacheKey');
      cache.add(MapEntry(cacheKey, jsonData));
    }
  }

  Future<void> getBadgeDataFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    List<MapEntry<String, Map<String, dynamic>>> badgeDataList = [];

    for (var file in files) {
      if (file is File &&
          file.path.endsWith('.json') &&
          !file.path.contains('data_')) {
        try {
          String jsonString = await file.readAsString();
          Map<String, dynamic> jsonData = jsonDecode(jsonString);

          if (jsonData.containsKey('messages') &&
              jsonData['messages'] is List) {
            badgeDataList.add(MapEntry(file.uri.pathSegments.last, jsonData));
          } else {
            logger.i('Skipping invalid badge file: ${file.path}');
          }
        } catch (e) {
          logger.i('Error parsing file ${file.path}: $e');
        }
      }
    }
    imageCacheProvider.savedBadgeCache = badgeDataList;
  }

  Data jsonToData(Map<String, dynamic> jsonData) {
    try {
      Data data = Data.fromJson(jsonData);
      return data;
    } catch (e) {
      if (e.toString().contains("Missing \"messages\" key")) {
        logger.w('Fixing missing "messages" key in badge data');

        Map<String, dynamic> fixedJsonData =
            Map<String, dynamic>.from(jsonData);
        fixedJsonData['messages'] = [
          {
            'text': jsonData['text'] ?? ['00'],
            'flash': jsonData['flash'] ?? false,
            'marquee': jsonData['marquee'] ?? false,
            'speed': jsonData['speed'] ?? '0x70',
            'mode': jsonData['mode'] ?? '0x00',
            'invert': jsonData['invert'] ?? false
          }
        ];

        return Data.fromJson(fixedJsonData);
      } else {
        logger.e('Error parsing badge data: $e');
        rethrow;
      }
    }
  }

  Future<void> shareBadgeData(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      File file = File(filePath);
      if (await file.exists()) {
        final result = await SharePlus.instance
            .share(ShareParams(files: [XFile(filePath)]));
        if (result.status == ShareResultStatus.success) {
          logger.i('File shared successfully');
        } else {
          logger.i('Error sharing file');
        }
      } else {
        logger.i('File not found: $filePath');
      }
    } catch (e) {
      logger.i('Error sharing file: $e');
    }
  }

  Future<void> deleteFile(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('File deleted: $filePath');
      } else {
        logger.i('File not found: $filePath');
      }
    } catch (e) {
      logger.i('Error deleting file: $e');
    }
  }

  Future<bool> renameBadge(String oldFilename, String newName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final oldPath = '${directory.path}/$oldFilename';
      final newFilename = '$newName.json';
      final newPath = '${directory.path}/$newFilename';

      final oldFile = File(oldPath);
      if (!await oldFile.exists()) {
        logger.w('renameBadge: source file not found: $oldPath');
        return false;
      }
      if (await File(newPath).exists()) {
        logger
            .w('renameBadge: a badge with that name already exists: $newPath');
        return false;
      }

      await oldFile.rename(newPath);
      logger.i('Renamed badge on disk: $oldFilename → $newFilename');

      await BadgeTextStorage.moveOriginalText(oldFilename, newFilename);

      final cache = imageCacheProvider.savedBadgeCache;
      final idx = cache.indexWhere((e) => e.key == oldFilename);
      if (idx >= 0) {
        cache[idx] = MapEntry(newFilename, cache[idx].value);
      }
      imageCacheProvider.notify();

      return true;
    } catch (e) {
      logger.e('Error renaming badge: $e');
      return false;
    }
  }

  Future<void> saveImageWithName(
      List<List<bool>> imageData, String customName) async {
    List<List<int>> image = List.generate(
        imageData.length, (i) => List<int>.filled(imageData[i].length, 0));

    for (int i = 0; i < imageData.length; i++) {
      for (int j = 0; j < imageData[i].length; j++) {
        image[i][j] = imageData[i][j] ? 1 : 0;
      }
    }

    String safeName = customName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    String filename = 'data_${safeName}_$timestamp.json';

    logger.d('Saving named clipart to file: $filename');

    String jsonData = jsonEncode(image);
    await _writeToFile(filename, jsonData);
    await _addImageDataToCache(image, filename);
  }

  Future<bool> importBadgeFromJson(Map<String, dynamic> json) async {
    try {
      Map<String, dynamic> badgeJson;
      String baseName;
      if (json.containsKey('badge') && json.containsKey('name')) {
        badgeJson = Map<String, dynamic>.from(json['badge'] as Map);
        baseName = (json['name'] as String?)?.trim() ?? '';
      } else {
        badgeJson = json;
        baseName = '';
      }
      if (baseName.isEmpty) {
        baseName = 'Imported Badge';
      }
      Data data = Data.fromJson(badgeJson);
      String filename = await _uniqueBadgeFilename(baseName);
      await _writeToFile('$filename.json', jsonEncode(data.toJson()));
      logger.d('Imported badge from QR: $filename');
      return true;
    } catch (e) {
      logger.i('Error importing badge from QR: $e');
      return false;
    }
  }

  Future<String> _uniqueBadgeFilename(String baseName) async {
    final directory = await getApplicationDocumentsDirectory();
    String candidate = baseName;
    int counter = 1;
    while (await File('${directory.path}/$candidate.json').exists()) {
      candidate = '$baseName ($counter)';
      counter++;
    }
    return candidate;
  }

  Future<bool> importBadgeData(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'gif'],
      );

      if (result.isEmpty) {
        ToastUtils().showToast('No file selected');
        return false;
      }

      final pickedFile = result.first;
      File file = File(pickedFile.path!);

      if (file.path.toLowerCase().endsWith('.gif')) {
        final fileName = file.uri.pathSegments.last.replaceAll('.gif', '.json');

        final hexFrames =
            imageUtils.convertGifFramesToLEDHex(await file.readAsBytes());

        Data data = Data.fromJson({
          "messages": [
            {
              "text": hexFrames,
              "flash": false,
              "marquee": false,
              "speed": "0x70",
              "mode": "0x05"
            }
          ],
        });

        await _writeToFile(fileName, jsonEncode(data.toJson()));

        logger.d('Imported badge: $fileName, data: $data');

        return true;
      } else if (file.path.toLowerCase().endsWith('.json')) {
        Data data = Data.fromJson(jsonDecode(await file.readAsString()));

        await _writeToFile(pickedFile.name, jsonEncode(data.toJson()));

        logger.d('Imported badge to: ${pickedFile.name}, data: $data');

        return true;
      } else {
        throw Exception('Only .gif and .json are supported!');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing badge: $e')),
        );
      }
      return false;
    }
  }

  Future<bool> importClipart(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result.isEmpty) {
        ToastUtils().showToast('No file selected');
        return false;
      }

      final pickedFile = result.first;
      File file = File(pickedFile.path!);

      String originalName = pickedFile.name;

      String baseName =
          originalName.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');

      String safeName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      if (safeName.isEmpty || safeName == 'data') {
        safeName = 'Imported_Clipart';
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String newFilename = 'data_${safeName}_$timestamp.json';

      String content = await file.readAsString();
      final List<dynamic> decodedData = jsonDecode(content);

      if (decodedData.isNotEmpty && decodedData[0] is List) {
        await _writeToFile(newFilename, content);

        final List<List<dynamic>> imageData = decodedData.cast<List<dynamic>>();
        List<List<int>> intImageData =
            imageData.map((list) => list.cast<int>()).toList();

        await _addImageDataToCache(imageData, newFilename);
        imageCacheProvider.clipartsCache[newFilename] = intImageData;

        logger.d('Clipart imported successfully: $newFilename');
        ToastUtils().showToast('Clipart imported successfully!');
        return true;
      } else {
        throw Exception(
            'Invalid Clipart Format: File does not contain badge data.');
      }
    } catch (e) {
      logger.i('Error importing clipart: $e');

      return false;
    }
  }

  Future<void> exportClipart(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      File file = File(filePath);
      if (await file.exists()) {
        String cleanName = 'BadgeMagic_Clipart';

        if (filename.startsWith('data_')) {
          String namePart = filename.substring(5);
          int lastUnderscore = namePart.lastIndexOf('_');

          if (lastUnderscore != -1) {
            String extractedName = namePart.substring(0, lastUnderscore);
            if (extractedName.isNotEmpty) {
              cleanName = extractedName;
            }
          }
        }

        String cleanFilename = '$cleanName.json';

        String fileContent = await file.readAsString();
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$cleanFilename';

        File tempFile = File(tempFilePath);
        await tempFile.writeAsString(fileContent);

        final result = await SharePlus.instance
            .share(ShareParams(files: [XFile(tempFilePath)]));

        if (result.status == ShareResultStatus.success) {
          logger.i('Clipart exported successfully as $cleanFilename');
        } else {
          logger.i('Error exporting clipart');
        }
      } else {
        logger.i('Clipart file not found: $filePath');
      }
    } catch (e) {
      logger.i('Error exporting clipart: $e');
    }
  }
}
