import 'dart:ui' as ui;
import 'dart:ui';

import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  late double originalHeight;
  late double originalWidth;

  late ui.Picture picture;

  //convert the 2D list to Uint8List
  //this funcction will be ustilised to convert the user drawn badge to Uint8List
  //and thus will be able to display with other vectors in the badge
  Future<Uint8List> convert2DListToUint8List(List<List<int>> twoDList) async {
    int height = twoDList.length;
    int width = twoDList[0].length;

    // Create a buffer to hold the pixel data
    Uint8List pixels =
        Uint8List(width * height * 4); // 4 bytes per pixel (RGBA)

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int value = twoDList[y][x] == 1 ? 0 : 255;
        int offset = (y * width + x) * 4;
        pixels[offset] = value; // Red
        pixels[offset + 1] = value; // Green
        pixels[offset + 2] = value; // Blue
        pixels[offset + 3] = 255; // Alpha
      }
    }

    // Create an ImmutableBuffer from the pixel data
    ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);

    // Create an ImageDescriptor from the buffer
    ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    // Instantiate a codec
    ui.Codec codec = await descriptor.instantiateCodec();

    // Get the first frame from the codec
    ui.FrameInfo frameInfo = await codec.getNextFrame();

    // Get the image from the frame
    ui.Image image = frameInfo.image;

    // Convert the image to PNG format
    ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  //function that generates the Picture from the given asset
  Future<void> _loadSVG(String asset) async {
    //loading the Svg from the assets
    String svgString = await rootBundle.loadString(asset);

    // Load SVG picture and information
    final SvgStringLoader svgStringLoader = SvgStringLoader(svgString);
    final PictureInfo pictureInfo = await vg.loadPicture(svgStringLoader, null);
    picture = pictureInfo.picture;

    //setting the origin heigh and width of the svg
    originalHeight = pictureInfo.size.height;
    originalWidth = pictureInfo.size.width;
  }

  //function to load and scale the svg according to the badge size
  Future<ui.Image> _scaleSVG(
      ui.Image inputImage, double targetHeight, double targetWidth) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder,
        Rect.fromPoints(Offset.zero, Offset(targetWidth, targetHeight)));

    double scaleX = targetWidth / inputImage.width;
    double scaleY = targetHeight / inputImage.height;

    double scale = scaleX < scaleY ? scaleX : scaleY;

    double dx = (targetWidth - (inputImage.width * scale)) / 2;
    double dy = (targetHeight - (inputImage.height * scale)) / 2;
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    canvas.drawImage(inputImage, Offset.zero, Paint());

    final ui.Image imgByteData = await recorder
        .endRecording()
        .toImage(targetWidth.ceil(), targetHeight.ceil());

    return imgByteData;
  }

  //function to convert the ui.Image to byte array
  Future<Uint8List?> _convertImageToByteArray(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData?.buffer.asUint8List();
  }

  //function to convert the byte array to 2D list of pixels
  List<List<int>> _convertUint8ListTo2DList(
      Uint8List byteArray, int width, int height) {
    //initialize the 2D list of pixels
    List<List<int>> pixelArray =
        List.generate(height, (i) => List<int>.filled(width, 0));
    int bytesPerPixel = 4; // RGBA format (4 bytes per pixel)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = (y * width + x) * bytesPerPixel;
        if (index + bytesPerPixel <= byteArray.length) {
          int a = byteArray[index + 3];
          int color = (a << 24);
          pixelArray[y][x] = color;
        } else {
          // Handle out-of-bounds case gracefully, e.g., fill with a default color
          pixelArray[y][x] = Colors.transparent.value;
        }
      }
    }
    return pixelArray;
  }

  //function to trim the svg
  Future<ui.Image> _trimSVG(ui.Image inputImage) async {
    final ByteData? byteData =
        await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Failed to get byte data from image');
    }

    final int width = inputImage.width;
    final int height = inputImage.height;
    final Uint8List pixels = byteData.buffer.asUint8List();

    int top = 0, bottom = height - 1, left = 0, right = width - 1;
    bool found = false;

    found = false;
    // Find the left boundary
    for (int x = 0; x < width && !found; x++) {
      for (int y = 0; y < height; y++) {
        final int offset = (y * width + x) * 4;
        if (pixels[offset + 3] > 0) {
          left = x;
          found = true;
          break;
        }
      }
    }

    found = false;
    // Find the right boundary
    for (int x = width - 1; x >= 0 && !found; x--) {
      for (int y = 0; y < height; y++) {
        final int offset = (y * width + x) * 4;
        if (pixels[offset + 3] > 0) {
          right = x;
          found = true;
          break;
        }
      }
    }

    final int newWidth = right - left + 1;
    final int newHeight = bottom - top + 1;

    final PictureRecorder trimRecorder = ui.PictureRecorder();
    final Canvas trimCanvas = Canvas(
        trimRecorder,
        Rect.fromPoints(
            Offset.zero, Offset(newWidth.toDouble(), newHeight.toDouble())));

    final Paint paint = ui.Paint();
    trimCanvas.drawImageRect(
        inputImage,
        Rect.fromLTWH(left.toDouble(), top.toDouble(), newWidth.toDouble(),
            newHeight.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        paint);

    final trimmedImage =
        await trimRecorder.endRecording().toImage(newWidth, newHeight);

    return trimmedImage;
  }

  // Trims an image to the tight bounding box of its non-transparent content on
  // all four sides. Used (display only) to strip each SVG's inconsistent
  // viewBox padding so the icon itself drives its rendered size.
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
    if (right < left || bottom < top) return inputImage; // fully transparent

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

  // Scales an image so its longest side fits `target`, then centers it inside a
  // `target` x `target` square. Display only: gives every clipart a uniform
  // square footprint while preserving aspect ratio (no stretch, no crop).
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

  //function to generate the view for the Dialog from the given asset
  //
  // DISPLAY ONLY (clipart picker + inline text-field previews) — produces a
  // uniform square so all cliparts render at a consistent size in the grid.
  // The badge / preview-bar encoding is generateLedHex (separate function).
  // We trim each SVG's padding and normalize into a uniform square so all
  // cliparts render at a consistent size in the grid.
  Future<ui.Image> generateImageView(String asset) async {
    await _loadSVG(asset);
    ui.Image image =
        await picture.toImage(originalWidth.toInt(), originalHeight.toInt());
    final ui.Image content = await _trimToContent(image);
    return _fitInSquare(content, 30);
  }

  //function to generate the LED hex from the given asset
  Future<List<String>> generateLedHex(String asset) async {
    await _loadSVG(asset);
    ui.Image image =
        await picture.toImage(originalWidth.toInt(), originalHeight.toInt());

    // Trim each SVG's inconsistent viewBox padding (all four sides) BEFORE
    // scaling, so the artwork itself — not the padding — drives how tall the
    // clipart renders on the badge. _scaleSVG still fits it into 11x44 with
    // aspect-preserving min-scale, so shapes are never stretched or cropped:
    // square/tall icons fill the full height, while genuinely wide-thin shapes
    // stay proportionally thin. This makes the height ratio consistent across
    // all cliparts in the preview bar / real badge.
    final ui.Image content = await _trimToContent(image);
    final ui.Image scaledImage = await _scaleSVG(content, 11, 44);
    final ui.Image trimmedImage = await _trimSVG(scaledImage);
    final Uint8List? byteArray = await _convertImageToByteArray(trimmedImage);
    final List<List<int>> pixelArray = _convertUint8ListTo2DList(
        byteArray!, trimmedImage.width, trimmedImage.height);
    for (int x = 0; x < pixelArray.length; x++) {
      for (int y = 0; y < pixelArray[x].length; y++) {
        if (pixelArray[x][y] != 0) {
          pixelArray[x][y] = 1;
        }
      }
    }
    return Converters.convertBitmapToLEDHex(pixelArray, true);
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
