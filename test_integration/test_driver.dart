// ignore_for_file: avoid_print

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = 'screenshots/$screenshotName-$timeStamp.png';
      print('Writing screenshot to $filePath');

      final File image = await File(filePath).create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
