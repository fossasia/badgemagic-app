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
  Future<List<String>> messageTohex(String message, bool isInverted,
      {TextStyle? textStyle}) async {
    if (textStyle != null) {
      List<List<bool>> matrix = await renderTextToMatrix(message, textStyle);
      List<List<int>> intMatrix =
          matrix.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
      List<String> hex = convertBitmapToLEDHex(intMatrix, true);
      if (isInverted) {
        hex = invertHex(hex.join()).split('');
        hex = padHexString(hex);
      }
      logger.d("Hex strings (rendered): $hex");
      return hex;
    } else {
      List<String> hexStrings = [];
      for (int x = 0; x < message.length; x++) {
        if (message[x] == '<' &&
            message[min(x + 5, message.length - 1)] == '>') {
          int index = int.parse(message[x + 2] + message[x + 3]);
          var key = controllerData.imageCache.keys.toList()[index];
          if (key is List) {
            String filename = key[0];
            List<dynamic>? decodedData =
                await fileHelper.readFromFile(filename);
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
      logger.d("Hex strings (legacy): $hexStrings");
      return hexStrings;
    }
  }

  Future<List<List<bool>>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int rows = 15,
    int scale = 12,
  }) async {
    textStyle = textStyle.copyWith(
      fontSize: 13.0,
      fontWeight: FontWeight.bold,
    );
    final RegExp regex = RegExp(r'<<(\d{2})>>');
    List<_Segment> segments = [];
    int lastMatchEnd = 0;
    for (final match in regex.allMatches(message)) {
      if (match.start > lastMatchEnd) {
        segments.add(_Segment(
          text: message.substring(lastMatchEnd, match.start),
          isEmoji: false,
        ));
      }
      String emojiIndex = match.group(1)!;
      segments.add(_Segment(text: emojiIndex, isEmoji: true));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < message.length) {
      segments
          .add(_Segment(text: message.substring(lastMatchEnd), isEmoji: false));
    }
    double fontSize = (textStyle.fontSize ?? 16) * scale;
    double emojiWidth = fontSize * 1.27;
    double totalWidth = 0.0;
    double spacing = 2.0 * scale; 

    for (var segment in segments) {
      if (!segment.isEmoji) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: segment.text,
            style: textStyle.copyWith(fontSize: fontSize),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        totalWidth += textPainter.width + spacing;
      } else {
        totalWidth += emojiWidth + spacing;
      }
    }
    int canvasWidth = totalWidth.ceil();
    int canvasHeight = rows * scale;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()));
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        bgPaint);

    double currentX = 0;
    double centerY = canvasHeight / 2;

    for (var segment in segments) {
      if (!segment.isEmoji) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: segment.text,
            style: textStyle.copyWith(
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
            canvas, Offset(currentX, centerY - textPainter.height / 2));
        currentX += textPainter.width + spacing;
      } else {
        int index = int.parse(segment.text);
        List keys = controllerData.imageCache.keys.toList();
        if (index < keys.length) {
          var key = keys[index];
          Uint8List? emojiBytes = controllerData.imageCache[key];
          if (emojiBytes != null) {
            
            ui.Codec codec = await ui.instantiateImageCodec(emojiBytes);
            ui.FrameInfo fi = await codec.getNextFrame();
            ui.Image originalImage = fi.image;

         
            double aspectRatio = originalImage.width / originalImage.height;
            double scaledHeight = emojiWidth / aspectRatio;

      
            codec = await ui.instantiateImageCodec(
              emojiBytes,
              targetWidth: emojiWidth.toInt(),
              targetHeight: scaledHeight.ceil(),
            );
            fi = await codec.getNextFrame();
            ui.Image emojiImage = fi.image;
            canvas.drawImage(emojiImage,
                Offset(currentX, centerY - scaledHeight / 2), Paint());
            currentX += emojiWidth + spacing;
          }
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
    const int brightnessThreshold = 180;
    int matrixCols = (canvasWidth / scale).ceil();
    List<List<bool>> matrix =
        List.generate(rows, (_) => List.generate(matrixCols, (_) => false));

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < matrixCols; col++) {
        int darkCount = 0;
        int validPixels = 0;

        for (int y = 0; y < scale; y++) {
          for (int x = 0; x < scale; x++) {
            int pixelX = col * scale + x;
            int pixelY = row * scale + y;
            if (pixelX < canvasWidth && pixelY < canvasHeight) {
              int index = (pixelY * canvasWidth + pixelX) * 4;

              if (index + 3 < data.length) {
                int r = data[index];
                int g = data[index + 1];
                int b = data[index + 2];

                int brightness = ((r + g + b) / 3).round();
                if (brightness < brightnessThreshold) {
                  darkCount++;
                }
                validPixels++;
              }
            }
          }
        }
        double threshold = validPixels > 0 ? 0.3 : 0.0;
        matrix[row][col] =
            validPixels > 0 && (darkCount / validPixels) > threshold;
      }
    }
    return _cleanupMatrix(matrix);
  }

  List<List<bool>> _cleanupMatrix(List<List<bool>> matrix) {
    int rows = matrix.length;
    int cols = matrix[0].length;
    List<List<bool>> cleaned =
        List.generate(rows, (i) => List.generate(cols, (j) => matrix[i][j]));

    for (int i = 1; i < rows - 1; i++) {
      for (int j = 1; j < cols - 1; j++) {
        if (cleaned[i][j]) {
          bool hasNeighbor = false;
          if (cleaned[i - 1][j] ||
              cleaned[i + 1][j] ||
              cleaned[i][j - 1] ||
              cleaned[i][j + 1]) {
            hasNeighbor = true;
          }
          if (!hasNeighbor) {
            cleaned[i][j] = false;
          }
        }
      }
    }
    int startCol = 0;
    int endCol = cols - 1;

    bool hasContent = false;
    for (int j = 0; j < cols; j++) {
      bool isEmpty = true;
      for (int i = 0; i < rows; i++) {
        if (cleaned[i][j]) {
          isEmpty = false;
          hasContent = true;
          break;
        }
      }
      if (!isEmpty) {
        startCol = j;
        break;
      }
    }
    if (hasContent) {
      for (int j = cols - 1; j >= 0; j--) {
        bool isEmpty = true;
        for (int i = 0; i < rows; i++) {
          if (cleaned[i][j]) {
            isEmpty = false;
            break;
          }
        }
        if (!isEmpty) {
          endCol = j;
          break;
        }
      }
    } else {
      return matrix;
    }
    int paddedStart = max(0, startCol - 1);
    int paddedEnd = min(cols - 1, endCol + 1);
    int trimmedWidth = paddedEnd - paddedStart + 1;

    List<List<bool>> trimmed = List.generate(rows,
        (i) => List.generate(trimmedWidth, (j) => cleaned[i][paddedStart + j]));

    return trimmed;
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
