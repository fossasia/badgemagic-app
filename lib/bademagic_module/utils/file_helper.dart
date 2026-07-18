import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/imageprovider.dart';
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

  // Add a new image to the cache
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
          // Read the file as bytes
          Uint8List fileBytes = await file.readAsBytes();
          // Decode the bytes to a string using utf-8 encoding
          String content = utf8.decode(fileBytes);

          if (content.isNotEmpty) {
            // Ensure correct type casting
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

  // Remove an image from the cache
  void removeFromCache(int key) {
    if (imageCacheProvider.imageCache.containsKey(key)) {
      imageCacheProvider.imageCache.remove(key);
      imageCacheProvider.availableKeys
          .add(key); // Add key to the pool of available keys
    }
  }

  // Generate a Uint8List from a 2D list (image data) and add it to the cache
  Future<void> _addImageDataToCache(
      List<List<dynamic>> imageData, String filename) async {
    // Convert List<List<dynamic>> to List<List<int>>
    List<List<int>> intImageData =
        imageData.map((list) => list.cast<int>()).toList();
    Uint8List imageBytes =
        await imageUtils.convert2DListToUint8List(intImageData);
    addToCache(imageBytes, filename);
  }

  // Trim empty left/right columns only. Row count is preserved because the
  // LED-hex pipeline assumes exactly 11 rows.
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

  // Pad/crop to 11 rows so legacy short-matrix files don't crash the renderer.
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
    // Convert the 2D list of int to a JSON string
    String jsonData = jsonEncode(trimmed);

    // Get the application's document directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    logger.d('File path: $filePath');

    final file = File(filePath);

    // Check if the file exists
    if (await file.exists()) {
      logger.d('File found: $filename');
      // Overwrite the content of the existing file
      await file.writeAsString(jsonData);
      logger.d('File content updated: $filename');
    } else {
      // Create a new file and write the content
      await file.create(recursive: true);
      await file.writeAsString(jsonData);
      logger.d('New file created and content written: $filename');
    }
    return true;
  }

  // Read all files, parse the 2D lists, and add to cache
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
          // Ensure correct type casting
          final List<dynamic> decodedData = jsonDecode(content);
          final List<List<dynamic>> imageData =
              decodedData.cast<List<dynamic>>();
          await _addImageDataToCache(imageData, file.uri.pathSegments.last);
        }
      }
    }
  }

  // Returns true if the clipart was persisted, false if rejected as empty.
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
      // Get the document directory path
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      // Check if the file exists
      File file = File(filePath);
      if (await file.exists()) {
        // Read the file's current content
        String jsonString = await file.readAsString();

        // Parse the JSON data
        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        // Check if 'messages' exists and is a list
        if (jsonData.containsKey('messages') && jsonData['messages'] is List) {
          List<dynamic> messages = jsonData['messages'];

          // Assuming you want to update the first message's 'text'
          if (messages.isNotEmpty && messages[0] is Map<String, dynamic>) {
            Map<String, dynamic> message = messages[0];

            // Update the 'text' field with the new text
            message['text'] = newText;

            // Convert the updated data back to a JSON string
            String updatedJsonString = jsonEncode(jsonData);

            // Write the updated JSON string back to the file
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
      // Convert Data object to JSON string
      String jsonString = jsonEncode(jsonData);

      // Get the document directory path
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename.json';

      // Save JSON string to the file
      File file = File(filePath);
      await file.writeAsString(jsonString);

      // Update the cache using the new utility method
      _updateSavedBadgeCache(filename, jsonData);

      logger.i('Data saved to $filePath');
    } catch (e) {
      logger.i('Error saving data: $e');
    }
  }

  // Utility method to update savedBadgeCache
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

          // Defensive: Only add if valid structure
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

//function that takes JsonSData and returns the Data object
  Data jsonToData(Map<String, dynamic> jsonData) {
    try {
      // Convert JSON data to Data object
      Data data = Data.fromJson(jsonData);
      return data;
    } catch (e) {
      // If there's an error with the 'messages' key missing, add it with default values
      if (e.toString().contains("Missing \"messages\" key")) {
        logger.w('Fixing missing "messages" key in badge data');

        // Create a default message structure if missing
        Map<String, dynamic> fixedJsonData =
            Map<String, dynamic>.from(jsonData);
        fixedJsonData['messages'] = [
          {
            'text': jsonData['text'] ?? ['00'],
            'flash': jsonData['flash'] ?? false,
            'marquee': jsonData['marquee'] ?? false,
            'speed': jsonData['speed'] ?? '0x70', // Default to Speed.one
            'mode': jsonData['mode'] ?? '0x00', // Default to Mode.left
            'invert': jsonData['invert'] ?? false
          }
        ];

        return Data.fromJson(fixedJsonData);
      } else {
        // For other errors, rethrow
        logger.e('Error parsing badge data: $e');
        rethrow;
      }
    }
  }

  Future<void> shareBadgeData(String filename) async {
    try {
      // Get the document directory path
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      // Check if the file exists
      File file = File(filePath);
      if (await file.exists()) {
        // Use share_plus to share the file
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

  Future<bool> importBadgeData(context) async {
    try {
      // Open file picker to select a JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'gif'],
      );

      if (result == null || result.files.isEmpty) {
        ToastUtils().showToast('No file selected');
        return false;
      }

      File file = File(result.files.single.path!);

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

        await _writeToFile(result.files.single.name, jsonEncode(data.toJson()));

        logger.d('Imported badge to: ${result.files.single.name}, data: $data');

        return true;
      } else {
        throw Exception('Only .gif and .json are supported!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing badge: $e')),
      );
      return false;
    }
  }

  Future<bool> importClipart(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        ToastUtils().showToast('No file selected');
        return false;
      }

      File file = File(result.files.single.path!);

      String originalName = result.files.single.name;

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
