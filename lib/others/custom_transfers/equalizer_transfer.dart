import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';
import 'package:logger/logger.dart';

Future<void> customTransferEqualizerAnimation(
    Future<void> Function(DataTransferManager) transferData, int speedLevel,
    {bool skipAdapterCheck = false}) async {
  if (!skipAdapterCheck && !await checkAdapterState()) return;

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int hardwareFrameCount = 8;
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Equalizer animation transfer...');

  List<Message> equalizerFrames = [];

  final equalizerAnimation = EqualizerAnimation();

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    equalizerAnimation.processAnimation(
        badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i('📊 Equalizer Frame $i hex: ${hexList.join(",")}');

    equalizerFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: equalizerFrames);
  DataTransferManager manager = DataTransferManager(data);
  try {
    await transferData(manager);
    logger.i('💡 Equalizer animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ Equalizer animation transfer failed: $e\n$st');
  }
}
