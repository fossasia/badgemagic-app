import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/badge_animation/ani_cycle.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';
import 'package:logger/logger.dart';

Future<void> customTransferCycleAnimation(
    Future<void> Function(DataTransferManager) transferData, int speedLevel,
    {bool skipAdapterCheck = false}) async {
  if (!skipAdapterCheck && !await checkAdapterState()) return;

  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Cycle animation transfer...');

  List<Message> cycleFrames = [];

  List<List<List<bool>>> selectedFrames = CycleAnimation().transferFrames();

  for (int i = 0; i < selectedFrames.length; i++) {
    List<List<bool>> frameBitmap = selectedFrames[i];

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        '🚴 Cycle Frame $i hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    cycleFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: cycleFrames);
  logger.i('🚴 Cycle Data object created. Starting transfer...');

  try {
    await transferData(DataTransferManager(data));
    logger.i('🚴 Cycle animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ Cycle animation transfer failed: $e\n$st');
  }
}
