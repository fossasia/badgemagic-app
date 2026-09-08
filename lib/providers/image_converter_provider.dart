import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageToBadgeConverter {
  static Future<List<List<bool>>?> pickAndConvertImage({
    int targetRows = 11,
    int targetCols = 44,
    int threshold = 128,
  }) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    final File file = File(pickedFile.path);
    final List<int> imageBytes = await file.readAsBytes();

    img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));
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

        // Estraggo i canali RGB
        num r = pixel.r;
        num g = pixel.g;
        num b = pixel.b;

        double luminance = (0.299 * r) + (0.587 * g) + (0.114 * b);

        grid[y][x] = luminance < threshold;
      }
    }

    return grid;
  }
}
