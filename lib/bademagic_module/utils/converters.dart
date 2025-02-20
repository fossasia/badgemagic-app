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

class _Segment {
  final String text;
  final bool isEmoji;
  _Segment({required this.text, required this.isEmoji});
}

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

  Future<List<List<bool>>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int cols = 44,
    int rows = 11,
    int scale = 40, // scale factor for better resolution
  }) async {
    // Parse the message into segments (plain text and emoji)
    final RegExp regex = RegExp(r'<<(\d{2})>>');
    List<_Segment> segments = [];
    int lastMatchEnd = 0;
    for (final match in regex.allMatches(message)) {
      if (match.start > lastMatchEnd) {
        segments.add(_Segment(
            text: message.substring(lastMatchEnd, match.start),
            isEmoji: false));
      }
      String emojiIndex = match.group(1)!;
      segments.add(_Segment(text: emojiIndex, isEmoji: true));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < message.length) {
      segments
          .add(_Segment(text: message.substring(lastMatchEnd), isEmoji: false));
    }

    // Determine the scaled font size and set emoji dimensions.
    double scaledFontSize = (textStyle.fontSize ?? 30) * scale;
    int canvasHeight = rows * scale;
    // Ensure the text fits vertically within the canvas (leave a tiny margin)
    if (scaledFontSize > canvasHeight * 0.96) {
      scaledFontSize = canvasHeight * 0.96;
    }
    double emojiWidth =
        scaledFontSize; // emojis are square, matching text height
    double emojiGap = scaledFontSize * 0.2; // gap between consecutive emojis

    // Measure one copy of the message (in scaled pixels)
    double singleCopyWidth = 0;
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].isEmoji) {
        double widthWithGap = emojiWidth;
        if (i < segments.length - 1 && segments[i + 1].isEmoji) {
          widthWithGap += emojiGap;
        }
        singleCopyWidth += widthWithGap;
      } else {
        final TextPainter tp = TextPainter(
          text: TextSpan(
              text: segments[i].text,
              style: textStyle.copyWith(fontSize: scaledFontSize)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        singleCopyWidth += tp.width;
      }
    }

    // fixedWidth is the display width (in scaled pixels)
    int fixedWidth = cols * scale;
    // For marquee effect, set gap equal to fixedWidth (so the message fully scrolls off before repeating)
    int gapWidth = fixedWidth;
    // Canvas width is one copy of the message plus the gap
    int canvasWidth = singleCopyWidth.ceil() + gapWidth;

    double centerY = canvasHeight / 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()));

    // Fill the background with white
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        bgPaint);

    // Draw one copy of the message starting at x=0
    double currentX = 0;
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (!segment.isEmoji) {
        final TextPainter tp = TextPainter(
          text: TextSpan(
              text: segment.text,
              style: textStyle.copyWith(
                  fontSize: scaledFontSize, color: Colors.black)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        // Compute descent so that letters with descenders are fully visible.
        var metrics = tp.computeLineMetrics();
        double descent = metrics.isNotEmpty ? metrics.first.descent : 0;
        // Offset the text so that the bottom of the glyphs is centered.
        double offsetY = centerY - (tp.height - descent) / 2;
        tp.paint(canvas, Offset(currentX, offsetY));
        currentX += tp.width;
      } else {
        int index = int.parse(segment.text);
        List keys = controllerData.imageCache.keys.toList();
        if (index < keys.length) {
          var key = keys[index];
          Uint8List? emojiBytes = controllerData.imageCache[key];
          if (emojiBytes != null) {
            ui.Codec codec = await ui.instantiateImageCodec(emojiBytes,
                targetWidth: emojiWidth.toInt(),
                targetHeight: emojiWidth.toInt());
            ui.FrameInfo fi = await codec.getNextFrame();
            ui.Image emojiImage = fi.image;
            double offsetY = centerY - emojiWidth / 2;
            Paint imagePaint = Paint();
            canvas.drawImage(emojiImage, Offset(currentX, offsetY), imagePaint);
          }
        }
        currentX += emojiWidth;
        if (i < segments.length - 1 && segments[i + 1].isEmoji) {
          currentX += emojiGap;
        }
      }
    }
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(canvasWidth, canvasHeight);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    final Uint8List data = byteData.buffer.asUint8List();

    // Downsample: For each cell (scale x scale block), count dark pixels.
    List<List<bool>> matrix = List.generate(
        rows, (_) => List.generate((canvasWidth / scale).ceil(), (_) => false));
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < (canvasWidth / scale).ceil(); col++) {
        int darkCount = 0;
        int totalCount = 0;
        for (int y = 0; y < scale; y++) {
          for (int x = 0; x < scale; x++) {
            int pixelX = col * scale + x;
            int pixelY = row * scale + y;
            int index = (pixelY * canvasWidth + pixelX) * 4;
            if (index + 3 < data.length) {
              int r = data[index];
              int g = data[index + 1];
              int b = data[index + 2];
              int brightness = ((r + g + b) / 3).round();
              if (brightness < 128) darkCount++;
              totalCount++;
            }
          }
        }
        matrix[row][col] = darkCount > (scale * scale * 0.2);
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
