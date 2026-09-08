import 'dart:io';

import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileStorage {
  static const Uuid _uuid = Uuid();

  static Future<String> filePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  static Future<File> write(String filename, String data) async {
    final path = await filePath(filename);
    logger.d('Writing to file: $path');
    return File(path).writeAsString(data);
  }

  static String generateUniqueFilename() {
    final String uniqueId = _uuid.v4();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'data_${timestamp}_$uniqueId.json';
  }
}
