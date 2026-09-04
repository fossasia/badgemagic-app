import 'dart:ui' as ui;

import 'package:badgemagic/others/converters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  late double originalHeight;
  late double originalWidth;

  late ui.Picture picture;

  Future<Uint8List> convert2DListToUint8List(List<List<int>> twoDList) async {
    int height = twoDList.length;
    int width = twoDList[0].length;

    Uint8List pixels = Uint8List(width * height * 4);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        bool isOn = twoDList[y][x] == 1;
        int offset = (y * width + x) * 4;
        pixels[offset] = 0;
        pixels[offset + 1] = 0;
        pixels[offset + 2] = 0;
        pixels[offset + 3] = isOn ? 255 : 0;
      }
    }

    ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);

    ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    ui.Codec codec = await descriptor.instantiateCodec();

    ui.FrameInfo frameInfo = await codec.getNextFrame();

    ui.Image image = frameInfo.image;

    ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  Future<void> _loadSVG(String asset) async {
    String svgString = await rootBundle.loadString(asset);

    final SvgStringLoader svgStringLoader = SvgStringLoader(svgString);
    final PictureInfo pictureInfo = await vg.loadPicture(svgStringLoader, null);
    picture = pictureInfo.picture;

    originalHeight = pictureInfo.size.height;
    originalWidth = pictureInfo.size.width;
  }

  Future<Uint8List?> _convertImageToByteArray(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData?.buffer.asUint8List();
  }

  List<List<int>> _convertUint8ListTo2DList(
      Uint8List byteArray, int width, int height) {
    List<List<int>> pixelArray =
        List.generate(height, (i) => List<int>.filled(width, 0));
    int bytesPerPixel = 4;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = (y * width + x) * bytesPerPixel;
        if (index + bytesPerPixel <= byteArray.length) {
          int a = byteArray[index + 3];
          int color = (a << 24);
          pixelArray[y][x] = color;
        } else {
          pixelArray[y][x] = Colors.transparent.value;
        }
      }
    }
    return pixelArray;
  }

  Future<ui.Image> _trimToContent(ui.Image inputImage) async {
    final ByteData? byteData =
        await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return inputImage;

    final int width = inputImage.width;
    final int height = inputImage.height;
    final Uint8List pixels = byteData.buffer.asUint8List();

    int top = height, bottom = -1, left = width, right = -1;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[(y * width + x) * 4 + 3] > 0) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }
    if (right < left || bottom < top) return inputImage;

    final int newWidth = right - left + 1;
    final int newHeight = bottom - top + 1;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()));
    canvas.drawImageRect(
        inputImage,
        Rect.fromLTWH(left.toDouble(), top.toDouble(), newWidth.toDouble(),
            newHeight.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint());
    return recorder.endRecording().toImage(newWidth, newHeight);
  }

  Future<ui.Image> _fitInSquare(ui.Image inputImage, int target) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, target.toDouble(), target.toDouble()));
    final int longest = inputImage.width > inputImage.height
        ? inputImage.width
        : inputImage.height;
    final double scale = target / longest;
    final double dx = (target - inputImage.width * scale) / 2;
    final double dy = (target - inputImage.height * scale) / 2;
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);
    canvas.drawImage(inputImage, Offset.zero, Paint());
    return recorder.endRecording().toImage(target, target);
  }

  Future<ui.Image> generateImageView(String asset) async {
    await _loadSVG(asset);
    ui.Image image =
        await picture.toImage(originalWidth.toInt(), originalHeight.toInt());
    final ui.Image content = await _trimToContent(image);
    return _fitInSquare(content, 30);
  }

  Future<ui.Image> _normalizeForBadge(ui.Image inputImage, int rows,
      {required bool fillHeight, int? maxWidth}) async {
    final ui.Image content = await _trimToContent(inputImage);
    final int longest =
        content.width > content.height ? content.width : content.height;
    final double basis =
        fillHeight ? content.height.toDouble() : longest.toDouble();
    double scale = rows / basis;
    if (maxWidth != null && content.width * scale > maxWidth) {
      scale = maxWidth / content.width;
    }
    final int w = (content.width * scale).round() < 1
        ? 1
        : (content.width * scale).round();
    final int h = (content.height * scale).round() < 1
        ? 1
        : (content.height * scale).round();
    final double dy = (rows - h) / 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), rows.toDouble()));
    canvas.drawImageRect(
        content,
        Rect.fromLTWH(
            0, 0, content.width.toDouble(), content.height.toDouble()),
        Rect.fromLTWH(0, dy, w.toDouble(), h.toDouble()),
        Paint());
    return recorder.endRecording().toImage(w, rows);
  }

  Future<List<String>> generateLedHex(String asset) async {
    final List<List<int>> matrix = await generateLedHexMatrix(asset);
    final bool trimColumns = !asset.toLowerCase().contains('arrow');
    return Converters.convertBitmapToLEDHex(matrix, trimColumns);
  }

  Future<List<List<int>>> generateLedHexMatrix(String asset) async {
    await _loadSVG(asset);
    ui.Image image =
        await picture.toImage(originalWidth.toInt(), originalHeight.toInt());

    final String name = asset.toLowerCase();
    final bool isArrow = name.contains('arrow');
    final bool isBar = name.contains('clip_bar');
    final bool isMustache = name.contains('mustache');

    ui.Image normalized;
    if (isArrow) {
      final ui.Image content = await _trimToContent(image);
      normalized = await _fitInSquare(content, 11);
    } else if (isBar) {
      normalized = await _normalizeForBadge(image, 11, fillHeight: false);
    } else if (isMustache) {
      normalized =
          await _normalizeForBadge(image, 11, fillHeight: true, maxWidth: 16);
    } else {
      normalized =
          await _normalizeForBadge(image, 11, fillHeight: true, maxWidth: 44);
    }

    final Uint8List? byteArray = await _convertImageToByteArray(normalized);
    final List<List<int>> pixelArray = _convertUint8ListTo2DList(
        byteArray!, normalized.width, normalized.height);
    for (int x = 0; x < pixelArray.length; x++) {
      for (int y = 0; y < pixelArray[x].length; y++) {
        if (pixelArray[x][y] != 0) {
          pixelArray[x][y] = 1;
        }
      }
    }
    return pixelArray;
  }

  List<List<List<bool>>> decodeGifFramesToBool(Uint8List gifBytes,
      {int width = 44, int height = 11}) {
    final gifImage = img.decodeGif(gifBytes);
    if (gifImage == null) {
      throw Exception('Failed to decode GIF');
    }

    final List<List<List<bool>>> frames = [];
    for (final frame in gifImage.frames) {
      img.Image image = img.copyResize(frame, width: width, height: height);
      image = img.grayscale(image);

      final List<List<bool>> bitmap = [];
      for (int y = 0; y < image.height; y++) {
        final List<bool> row = [];
        for (int x = 0; x < image.width; x++) {
          final img.Pixel pixel = image.getPixel(x, y);
          row.add(img.getLuminance(pixel) > 128);
        }
        bitmap.add(row);
      }
      frames.add(bitmap);
    }
    _centerFramesHorizontally(frames, width);
    return frames;
  }

  void _centerFramesHorizontally(List<List<List<bool>>> frames, int width) {
    int minCol = width;
    int maxCol = -1;
    for (final frame in frames) {
      for (final row in frame) {
        for (int x = 0; x < row.length; x++) {
          if (row[x]) {
            if (x < minCol) minCol = x;
            if (x > maxCol) maxCol = x;
          }
        }
      }
    }
    if (maxCol < minCol) return;

    final int contentWidth = maxCol - minCol + 1;
    final int widthMod = width % 8;
    final int rOff = widthMod == 0 ? 0 : (8 - widthMod) ~/ 2;
    final int shift = (width - contentWidth) ~/ 2 - rOff - minCol;
    if (shift == 0) return;

    for (int f = 0; f < frames.length; f++) {
      final frame = frames[f];
      for (int y = 0; y < frame.length; y++) {
        final List<bool> row = frame[y];
        final List<bool> shifted = List<bool>.filled(width, false);
        for (int x = 0; x < row.length; x++) {
          if (!row[x]) continue;
          final int nx = x + shift;
          if (nx >= 0 && nx < width) shifted[nx] = true;
        }
        frame[y] = shifted;
      }
    }
  }

  List<String> convertGifFramesToLEDHex(Uint8List gifBytes) {
    final gifImage = img.decodeGif(gifBytes);
    if (gifImage == null) {
      throw Exception('Failed to decode GIF');
    }

    List<String> hexFrames = [];

    for (final frame in gifImage.frames) {
      img.Image image = img.copyResize(frame, width: 48, height: 11);
      image = img.grayscale(image);

      List<List<int>> imageData = [];

      for (int y = 0; y < image.height; y++) {
        List<int> row = [];

        for (int x = 0; x < image.width; x++) {
          img.Pixel pixel = image.getPixel(x, y);
          int value = img.getLuminance(pixel) > 128 ? 1 : 0;
          row.add(value);
        }
        imageData.add(row);
      }

      hexFrames.addAll(Converters.convertBitmapToLEDHex(imageData, false));
    }

    return hexFrames;
  }
}
