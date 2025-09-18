import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

String getFontKey(
    String fontFamily, double fontSize, FontWeight weight, bool italic) {
  return '$fontFamily-${fontSize.round()}-${weight.index}-$italic';
}

class Converters {
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  DataToByteArrayConverter converter = DataToByteArrayConverter();
  ImageUtils imageUtils = ImageUtils();
  FileHelper fileHelper = FileHelper();

  static final Map<String, List<List<bool>>> _characterCache = {};

  List<String> _matrixToHex(List<List<bool>> matrix) {
    return List.generate(matrix.length, (i) {
      final binary = matrix[i].map((b) => b ? '1' : '0').join();
      return int.parse(binary, radix: 2).toRadixString(16).padLeft(2, '0');
    });
  }

  Future<Map<String, dynamic>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int rows = 11,
    required bool hasDescender, // for characters like j, g, p, q, y
  }) async {
    // Generate combined cache key using font properties and message
    final fontKey = getFontKey(
      textStyle.fontFamily ?? 'default',
      textStyle.fontSize ?? 14.0,
      textStyle.fontWeight ?? FontWeight.normal,
      textStyle.fontStyle == FontStyle.italic,
    );
    final cacheKey = '$fontKey-$message';

    // Check character cache
    if (_characterCache.containsKey(cacheKey)) {
      //print("Cache hit for $cacheKey");
      return {
        'matrix': _characterCache[cacheKey]!,
      };
    }

    int cols = 1;
    int scale = 1;
    // Calculate canvas size
    TextPainter widthCheckPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: textStyle.copyWith(
            color: Colors.black, fontSize: (textStyle.fontSize ?? 14) * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    widthCheckPainter.layout();
    final rawWidth = widthCheckPainter.width;
    // Check if character needs more width

    // Dynamic column calculation
    final actualCols = (rawWidth / scale).ceil().clamp(1, 16);

    //print("Actual cols: $actualCols");
    cols = actualCols;

    // Calculate final dimensions
    final int width = cols * scale;
    final int height = rows * scale;

    // Create single PictureRecorder and Canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Fill background
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    // Create text painter with final dimensions
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: textStyle.copyWith(
            color: Colors.black, fontSize: (textStyle.fontSize ?? 14) * scale),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: width.toDouble());
    Offset offset;
    if (hasDescender) {
      // For descender characters, align so descender can use bottom row
      final baselinePosition = height - 2; // Leave 1 unit at bottom
      offset = Offset(
        0,
        baselinePosition -
            textPainter
                .computeDistanceToActualBaseline(TextBaseline.alphabetic),
      );
    } else {
      // For normal characters, ensure bottom padding of 1 unit
      offset = Offset(
        0,
        (height - 1) - // Leave 1 unit at bottom
            textPainter
                .computeDistanceToActualBaseline(TextBaseline.alphabetic),
      );
    }

    //print("height: $height, offset: $offset");

    textPainter.paint(canvas, offset);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    final Uint8List data = byteData.buffer.asUint8List();

    List<List<bool>> matrix =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final int pixelIndex = (row * width + col) * 4;

        if (pixelIndex + 3 < data.length) {
          final int r = data[pixelIndex];
          final int g = data[pixelIndex + 1];
          final int b = data[pixelIndex + 2];
          final int brightness = ((r + g + b) / 3).round();

          matrix[row][col] = brightness < 128;
        }
      }
    }

    // Cache the result for future use
    _characterCache[cacheKey] = matrix;
    return {'matrix': matrix};
  }

  Future<List<String>> _processCustomFontMessage(
      String text, TextStyle style) async {
    try {
      List<Map<String, dynamic>> segments = [];
      // Parse text into segments
      String currentText = '';
      int i = 0;
      while (i < text.length) {
        if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
          if (currentText.isNotEmpty) {
            segments.add({'type': 'text', 'content': currentText});
            currentText = '';
          }
          segments.add(
              {'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
          i += 6;
        } else {
          currentText += text[i];
          i++;
        }
      }
      if (currentText.isNotEmpty) {
        segments.add({'type': 'text', 'content': currentText});
      }

      List<List<bool>> combinedMatrix = List.generate(11, (_) => []);

      // Process each segment
      for (var segment in segments) {
        if (segment['type'] == 'text') {
          String text = segment['content'];
          for (int i = 0; i < text.length; i++) {
            String char = text[i];
            bool hasDescender = "ypgqj".contains(char);
            final matrixData = await renderTextToMatrix(char, style,
                rows: 11, hasDescender: hasDescender);
            List<List<bool>> charMatrix = matrixData['matrix'];
            for (int row = 0; row < 11; row++) {
              combinedMatrix[row].addAll(charMatrix[row]);
            }
          }
        } else if (segment['type'] == 'image') {
          // Process bitmap
          int index = segment['index'];
          var key = controllerData.imageCache.keys.toList()[index];
          List<String> hexStrings;
          if (key is List) {
            String filename = key[0];
            List<dynamic>? decodedData =
                await fileHelper.readFromFile(filename);
            final List<List<dynamic>> image =
                decodedData!.cast<List<dynamic>>();
            List<List<int>> imageData =
                image.map((list) => list.cast<int>()).toList();
            hexStrings = convertBitmapToLEDHex(imageData, true);
          } else {
            hexStrings =
                await imageUtils.generateLedHex(controllerData.vectors[index]);
          }

          for (var hex in hexStrings) {
            for (int i = 0; i < 11; i++) {
              String hexByte = hex.substring(i * 2, (i * 2) + 2);
              int value = int.parse(hexByte, radix: 16);
              for (int bit = 0; bit < 8; bit++) {
                combinedMatrix[i].add(((value >> (7 - bit)) & 1) == 1);
              }
            }
          }
        }
      }

      int totalColumns =
          combinedMatrix.isNotEmpty ? combinedMatrix[0].length : 0;
      if (totalColumns % 8 != 0) {
        int paddingNeeded = 8 - (totalColumns % 8);
        final padding = List.filled(paddingNeeded, false);
        for (var row in combinedMatrix) {
          row.addAll(padding);
        }
      }

      List<String> allHexStrings = [];
      int segmentsCount =
          combinedMatrix.isNotEmpty ? combinedMatrix[0].length ~/ 8 : 0;

      for (int seg = 0; seg < segmentsCount; seg++) {
        final startCol = seg * 8;
        final endCol = startCol + 8;
        final segmentMatrix = List.generate(
            11, (row) => combinedMatrix[row].sublist(startCol, endCol));

        final List<String> hexBytes = _matrixToHex(segmentMatrix);
        final String segmentHex = hexBytes.join();
        allHexStrings.add(segmentHex);
      }

      return allHexStrings;
    } catch (e, stacktrace) {
      logger.e("Error processing custom font message",
          error: e, stackTrace: stacktrace);
      return [];
    }
  }

  Future<List<String>> messageTohex(String message, bool isInverted) async {
    if (message.isEmpty) return [];

    final fontProvider = GetIt.instance<FontProvider>();
    final usingCustomFont = fontProvider.selectedFont != null;

    // Process message in custom font mode or default mode
    List<String> hexStrings = usingCustomFont
        ? await _processCustomFontMessage(
            message, fontProvider.selectedTextStyle)
        : await _processDefaultFont(message);

    if (isInverted) {
      return _processInversion(hexStrings);
    }

    return hexStrings;
  }

  Future<List<String>> _processDefaultFont(String text) async {
    List<Map<String, dynamic>> segments = [];
    String currentText = '';

    int i = 0;
    while (i < text.length) {
      if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
        if (currentText.isNotEmpty) {
          segments.add({'type': 'text', 'content': currentText});
          currentText = '';
        }
        segments.add(
            {'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
        i += 6;
      } else {
        currentText += text[i];
        i++;
      }
    }
    if (currentText.isNotEmpty) {
      segments.add({'type': 'text', 'content': currentText});
    }

    List<String> hexStrings = [];
    for (var segment in segments) {
      if (segment['type'] == 'text') {
        String text = segment['content'];
        hexStrings.addAll(text
            .split('')
            .where((char) => converter.charCodes.containsKey(char))
            .map((char) => converter.charCodes[char]!)
            .toList());
      } else if (segment['type'] == 'image') {
        int index = segment['index'];
        var key = controllerData.imageCache.keys.toList()[index];
        if (key is List) {
          String filename = key[0];
          List<dynamic>? decodedData = await fileHelper.readFromFile(filename);
          final List<List<dynamic>> image = decodedData!.cast<List<dynamic>>();
          List<List<int>> imageData =
              image.map((list) => list.cast<int>()).toList();
          hexStrings.addAll(convertBitmapToLEDHex(imageData, true));
        } else {
          hexStrings.addAll(
              await imageUtils.generateLedHex(controllerData.vectors[index]));
        }
      }
    }
    return hexStrings;
  }

  List<String> _processInversion(List<String> hexStrings) {
    final inverted = invertHex(hexStrings.join()).split('');
    return padHexString(inverted);
  }

  //function to convert the bitmap to the LED hex format
  //it takes the 2D list of pixels and converts it to the LED hex format
  static List<String> convertBitmapToLEDHex(List<List<int>> image, bool trim) {
    // Determine the height and width of the image
    int height = image.length;
    int width = image.isNotEmpty ? image[0].length : 0;

    // Initialize variables to calculate padding and offsets
    int finalSum = 0;

    // Calculate and adjust for right-side padding
    for (int j = 0; j < width; j++) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i][j]; // Sum up pixel values in each column
      }
      if (sum == 0 && trim) {
        // If column sum is zero, mark all pixels in that column as -1
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        // Otherwise, update finalSum and exit loop
        finalSum += j;
        break;
      }
    }

    // Calculate and adjust for left-side padding
    for (int j = width - 1; j >= 0; j--) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i]
            [j]; // Sum up pixel values in each column (from right to left)
      }
      if (sum == 0 && trim) {
        // If column sum is zero, mark all pixels in that column as -1
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        // Otherwise, update finalSum and exit loop
        finalSum += (height - j - 1);
        break;
      }
    }

    // Calculate padding difference to align height to a multiple of 8
    int diff = 0;
    if ((height - finalSum) % 8 > 0) {
      diff = 8 - (height - finalSum) % 8;
    }

    // Calculate left and right offsets for padding
    int rOff = (diff / 2).floor();
    int lOff = (diff / 2).ceil();

    // Initialize a new list to accommodate the padded image
    List<List<int>> list =
        List.generate(height, (i) => List.filled(width + rOff + lOff, 0));

    // Fill the new list with the padded image data
    for (int i = 0; i < height; i++) {
      int k = 0;
      for (int j = 0; j < rOff; j++) {
        list[i][k++] = 0; // Fill right-side padding
      }
      for (int j = 0; j < width; j++) {
        if (image[i][j] != -1) {
          list[i][k++] = image[i][j]; // Copy non-padded pixels
        }
      }
      for (int j = 0; j < lOff; j++) {
        list[i][k++] = 0; // Fill left-side padding
      }
    }

    //logger.d("Padded image: $list");

    // Convert each 8-bit segment into hexadecimal strings
    List<String> allHexs = [];
    for (int i = 0; i < list[0].length ~/ 8; i++) {
      StringBuffer lineHex = StringBuffer();

      for (int k = 0; k < height; k++) {
        StringBuffer stBuilder = StringBuffer();

        // Construct 8-bit segments for each row
        for (int j = i * 8; j < i * 8 + 8; j++) {
          stBuilder.write(list[k][j]);
        }

        // Convert binary string to hexadecimal
        String hex = int.parse(stBuilder.toString(), radix: 2)
            .toRadixString(16)
            .padLeft(2, '0');
        lineHex.write(hex); // Append hexadecimal to line
      }

      allHexs.add(lineHex.toString()); // Store completed hexadecimal line
    }
    return allHexs; // Return list of hexadecimal strings
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
