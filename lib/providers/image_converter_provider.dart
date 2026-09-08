import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageToBadgeConverter {
  static Future<Uint8List?> pickImageBytes() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    return await pickedFile.readAsBytes();
  }

  static List<List<bool>>? convertBytesToGrid(
    Uint8List imageBytes, {
    int targetRows = 11,
    int targetCols = 44,
    int threshold = 128,
  }) {
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: targetCols,
      height: targetRows,
      interpolation: img.Interpolation.average,
    );

    List<List<bool>> grid = List.generate(
      targetRows,
      (_) => List.generate(targetCols, (_) => false),
    );

    for (int y = 0; y < targetRows; y++) {
      for (int x = 0; x < targetCols; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        double luminance =
            (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);
        grid[y][x] = luminance < threshold;
      }
    }
    return grid;
  }
}
