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
          final List<List>? image = decodedData?.cast<List<dynamic>>();
          List<List<int>> imageData =
              image!.map((list) => list.cast<int>()).toList();
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

  /// Updated: Render the given text using the provided [textStyle] onto an offscreen
  /// canvas and convert it to an LED matrix (11 rows x 44 columns).
 Future<List<List<bool>>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int cols = 44,
    int rows = 11,
    int scale = 10, // scale factor for better resolution
  }) async {
    // Parse the message for emoji placeholders
    final RegExp regex = RegExp(r'<<(\d{2})>>');
    List<_Segment> segments = [];
    int lastMatchEnd = 0;
    for (final match in regex.allMatches(message)) {
      if (match.start > lastMatchEnd) {
        segments.add(_Segment(
          text: message.substring(lastMatchEnd, match.start), 
          isEmoji: false
        ));
      }
      String emojiIndex = match.group(1)!;
      segments.add(_Segment(text: emojiIndex, isEmoji: true));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < message.length) {
      segments.add(_Segment(text: message.substring(lastMatchEnd), isEmoji: false));
    }

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

    double currentX = 0;
    double centerY = height / 2.0;
    double fontSize = (textStyle.fontSize ?? 16) * scale;
    double emojiWidth = fontSize*0.734; 

    for (var segment in segments) {
      if (!segment.isEmoji) {
        // Paint text
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: segment.text,
            style: textStyle.copyWith(
                color: Colors.black, fontSize: fontSize),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: width.toDouble() - currentX);
        double offsetY = centerY - textPainter.height / 2;
        textPainter.paint(canvas, Offset(currentX, offsetY));
        currentX += textPainter.width;
      } else {
        // Paint emoji
        int index = int.parse(segment.text);
        List keys = controllerData.imageCache.keys.toList();
        if (index < keys.length) {
          var key = keys[index];
          Uint8List? emojiBytes = controllerData.imageCache[key];
          if (emojiBytes != null) {
            ui.Codec codec = await ui.instantiateImageCodec(emojiBytes,
                targetWidth: emojiWidth.toInt(), targetHeight: emojiWidth.toInt());
            ui.FrameInfo fi = await codec.getNextFrame();
            ui.Image emojiImage = fi.image;
            double offsetY = centerY - emojiWidth / 2;
            Paint imagePaint = Paint();
            canvas.drawImage(emojiImage, Offset(currentX, offsetY), imagePaint);
            currentX += emojiWidth;
          }
        }
      }
    }

    // Convert canvas to image for downsampling
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    final Uint8List data = byteData.buffer.asUint8List();

    // Downsample to LED matrix
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
              int r = data[index], g = data[index + 1], b = data[index + 2];
              int brightness = ((r + g + b) / 3).round();
              sum += brightness;
              count++;
            }
          }
        }
        double avgBrightness = sum / count;
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
class _Segment {
  final String text;
  final bool isEmoji;
  _Segment({required this.text, required this.isEmoji});
}