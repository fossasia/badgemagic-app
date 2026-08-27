import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:logger/logger.dart';

const int animationBadgeHeight = 11;
const int animationBadgeWidth = 44;
const int animationFrameCount = 8;

List<List<int>> boolToIntBitmap(List<List<bool>> bitmap) {
  return bitmap.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
}

List<List<bool>> blankFrame([
  int height = animationBadgeHeight,
  int width = animationBadgeWidth,
]) {
  return List.generate(height, (_) => List.filled(width, false));
}

Message frameToMessage(
  List<List<bool>> frameBitmap, {
  Speed speed = Speed.eight,
}) {
  final List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
  final List<String> hexList =
      Converters.convertBitmapToLEDHex(intBitmap, false);
  return Message(
    text: hexList,
    mode: Mode.fixed,
    speed: speed,
    flash: false,
    marquee: false,
  );
}

Future<void> sendAnimationFrames({
  required String label,
  required List<List<List<bool>>> frames,
  required Future<void> Function(DataTransferManager) transferData,
  Speed speed = Speed.eight,
}) async {
  if (!await checkAdapterState()) return;

  final logger = Logger();
  logger.i('Starting $label animation transfer...');

  final Data data = Data(
    messages:
        frames.map((frame) => frameToMessage(frame, speed: speed)).toList(),
  );

  try {
    await transferData(DataTransferManager(data));
    logger.i('$label animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('$label animation transfer failed: $e\n$st');
  }
}
