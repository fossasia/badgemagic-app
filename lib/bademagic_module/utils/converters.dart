import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class Converters {
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  DataToByteArrayConverter converter = DataToByteArrayConverter();
  ImageUtils imageUtils = ImageUtils();
  FileHelper fileHelper = FileHelper();

  int controllerLength = 0;
  Future<List<String>> messageTohex(String message, bool isInverted) async {
    List<String> hexStrings = [];
    for (int x = 0; x < message.length; x++) {
      if (message[x] == '<' && message[min(x + 5, message.length - 1)] == '>') {
        int index = int.parse(message[x + 2] + message[x + 3]);
        var key = controllerData.imageCache.keys.toList()[index];
        if (key is List) {
          String filename = key[0];
          List<dynamic>? decodedData = await fileHelper.readFromFile(filename);
          final List<List<dynamic>> image = decodedData!.cast<List<dynamic>>();
          List<List<int>> imageData =
              image.map((list) => list.cast<int>()).toList();
          hexStrings += convertBitmapToLEDHex(imageData, true);
          x += 5;
        } else {
          List<String> hs =
              await imageUtils.generateLedHex(controllerData.vectors[index]);
          hexStrings.addAll(hs);
          x += 5;
        }
      } else {
        if (converter.charCodes.containsKey(message[x])) {
          hexStrings.add(converter.charCodes[message[x]]!);
        }
      }
    }
    if (isInverted) {
      hexStrings = invertHex(hexStrings.join()).split('');
      hexStrings = padHexString(hexStrings);
    }
    logger.d("Hex strings: $hexStrings");
    return hexStrings;
  }

  /// New: Render the given text using the provided [textStyle] onto an offscreen
  /// canvas and convert it to an LED matrix (11 rows x 44 columns).
  Future<List<List<bool>>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int cols = 44,
    int rows = 11,
    int scale = 10, // scale factor for better resolution
  }) async {
    // Calculate canvas size
    final int width = cols * scale;
    final int height = rows * scale;

    // Create a PictureRecorder and Canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Fill background with white
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    // Prepare the text painter
    // Multiply fontSize by scale to maintain sharpness
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: textStyle.copyWith(
            color: Colors.black, fontSize: (textStyle.fontSize ?? 16) * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width.toDouble());
    // Center the text on the canvas
    final Offset offset = Offset(
      (width - textPainter.width) / 2,
      (height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    // End recording and get the image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    final Uint8List data = byteData.buffer.asUint8List();

    // Downsample: For each cell (scale x scale block) compute average brightness.
    List<List<bool>> matrix =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        int sum = 0;
        int count = 0;
        for (int y = 0; y < scale; y++) {
          for (int x = 0; x < scale; x++) {
            int pixelX = col * scale + x;
            int pixelY = row * scale + y;
            int index =
                (pixelY * width + pixelX) * 4; // 4 bytes per pixel (RGBA)
            if (index + 3 < data.length) {
              // Calculate brightness using average of R, G, B channels.
              int r = data[index];
              int g = data[index + 1];
              int b = data[index + 2];
              int brightness = ((r + g + b) / 3).round();
              sum += brightness;
              count++;
            }
          }
        }
        double avgBrightness = sum / count;
        // Use a threshold of 128 to decide if the LED is on (true) or off (false)
        matrix[row][col] = avgBrightness < 128;
      }
    }
    return matrix;
  }

  static List<String> convertBitmapToLEDHex(List<List<int>> image, bool trim) {
    int height = image.length;
    int width = image.isNotEmpty ? image[0].length : 0;
    int finalSum = 0;
    for (int j = 0; j < width; j++) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i][j];
      }
      if (sum == 0 && trim) {
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        finalSum += j;
        break;
      }
    }
    for (int j = width - 1; j >= 0; j--) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i][j];
      }
      if (sum == 0 && trim) {
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        finalSum += (height - j - 1);
        break;
      }
    }
    int diff = 0;
    if ((height - finalSum) % 8 > 0) {
      diff = 8 - (height - finalSum) % 8;
    }
    int rOff = (diff / 2).floor();
    int lOff = (diff / 2).ceil();
    List<List<int>> list =
        List.generate(height, (i) => List.filled(width + rOff + lOff, 0));
    for (int i = 0; i < height; i++) {
      int k = 0;
      for (int j = 0; j < rOff; j++) {
        list[i][k++] = 0;
      }
      for (int j = 0; j < width; j++) {
        if (image[i][j] != -1) {
          list[i][k++] = image[i][j];
        }
      }
      for (int j = 0; j < lOff; j++) {
        list[i][k++] = 0;
      }
    }
    logger.d("Padded image: $list");
    List<String> allHexs = [];
    for (int i = 0; i < list[0].length ~/ 8; i++) {
      StringBuffer lineHex = StringBuffer();
      for (int k = 0; k < height; k++) {
        StringBuffer stBuilder = StringBuffer();
        for (int j = i * 8; j < i * 8 + 8; j++) {
          stBuilder.write(list[k][j]);
        }
        String hex = int.parse(stBuilder.toString(), radix: 2)
            .toRadixString(16)
            .padLeft(2, '0');
        lineHex.write(hex);
      }
      allHexs.add(lineHex.toString());
    }
    return allHexs;
  }

  static String invertHex(String hex) {
    StringBuffer invertedHex = StringBuffer();
    for (int i = 0; i < hex.length; i++) {
      String invertedHexDigit =
          (~int.parse(hex[i], radix: 16) & 0xF).toRadixString(16).toUpperCase();
      invertedHex.write(invertedHexDigit);
    }
    return invertedHex.toString();
  }

  List<String> padHexString(List<String> hexString) {
    List<List<int>> hexArray = hexStringToBool(hexString.join()).map((e) {
      return e.map((e) => e ? 1 : 0).toList();
    }).toList();
    for (int i = 0; i < hexArray.length; i++) {
      hexArray[i].insert(0, 1);
      hexArray[i].add(1);
    }
    return convertBitmapToLEDHex(hexArray, true);
  }
}
