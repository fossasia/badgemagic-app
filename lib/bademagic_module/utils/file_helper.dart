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
      // Reuse the lowest available key
      key = imageCacheProvider.availableKeys.first;
      imageCacheProvider.availableKeys.remove(key);
    } else {
      // Assign a new key
      key = imageCacheProvider.imageCache.length;
      while (imageCacheProvider.imageCache.containsKey(key)) {
        key++;
      }
    }
    //storing the user drawn clipart to the badge in the form of a list
    //the first element of the list is the filename and the second element is the key
    //while parsing the vector we can take the filename and generate the hex for that vector
    //therefore transfering the vector to the physiacl badge will be easier.
    imageCacheProvider.imageCache[[filename, key]] = imageData;
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
            imageCacheProvider.clipartsCache[file.path.split('/').last] =
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

  // Function to update the content of a file
// Function to update the content of a file with a 2D list of bools
  Future<void> updateClipart(String filename, List<List<int>> image) async {
    logger.d('Updating clipart: $filename');
    // Convert the 2D list of int to a JSON string
    String jsonData = jsonEncode(image);

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
  }

  // Read all files, parse the 2D lists, and add to cache
  Future<void> loadImageCacheFromFiles() async {
    generateClipartCache();
    getBadgeDataFiles();
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();

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
          await _addImageDataToCache(imageData, file.path.split('/').last);
        }
      }
    }
  }

  // Save a 2D list to a file with a unique name
  Future<void> saveImage(List<List<bool>> imageData) async {
    List<List<int>> image = List.generate(
        imageData.length, (i) => List<int>.filled(imageData[i].length, 0));

    //convert the 2D list of bool into 2D list of int
    for (int i = 0; i < imageData.length; i++) {
      for (int j = 0; j < imageData[i].length; j++) {
        image[i][j] = imageData[i][j] ? 1 : 0;
      }
    }

    // Generate a unique filename
    String filename = _generateUniqueFilename();

    logger.d('Saving image to file: $filename');

    // Convert the 2D list to JSON string
    String jsonData = jsonEncode(image);

    logger.d('JSON data: $jsonData');

    // Write the JSON string to a file
    await _writeToFile(filename, jsonData);

    logger.d('Image saved to file: $filename');

    //Add the image to the image cache after saving it to a file
    await _addImageDataToCache(image, filename);
  }

  Future<dynamic> readFromFile(String filename) async {
    try {
      final path = await _getFilePath(filename);
      final file = File(path);

      if (await file.exists()) {
        final content = await file.readAsString();
        final dynamic decodedData = jsonDecode(content);

        // Automatically return decoded JSON as a dynamic type
        return decodedData;
      } else {
        logger.d('File not found: $filename');
        return null;
      }
    } catch (e) {
      logger.e('Error reading file: $e');
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
      imageCacheProvider.savedBadgeCache
          .add(MapEntry("$filename.json", jsonData));
      logger.i('Data saved to $filePath');
    } catch (e) {
      logger.i('Error saving data: $e');
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
          // Read the JSON file
          String jsonString = await file.readAsString();

          // Convert JSON string to Data object
          Map<String, dynamic> jsonData = jsonDecode(jsonString);
          logger.d('JSON data: $jsonData');

          // Add the Data object to the list with the filename as the key
          badgeDataList.add(MapEntry(file.path.split('/').last, jsonData));
        } catch (e) {
          logger.i('Error parsing file ${file.path}: $e');
        }
      }
    }
    imageCacheProvider.savedBadgeCache = badgeDataList;
  }

//function that takes JsonSData and returns the Data object
  Data jsonToData(Map<String, dynamic> jsonData) {
    // Convert JSON data to Data object
    Data data = Data.fromJson(jsonData);
    return data;
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
        final result = await Share.shareXFiles([XFile(filePath)]);
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
}
