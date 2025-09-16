import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_cycle.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferCycleAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  // Use the same speed logic as Diamond/Cupid: always use Speed.eight for seamless animation
  // Cycle animation uses 8 selected frames from infinite back-and-forth movement
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Cycle animation transfer...');

  List<Message> cycleFrames = [];

  // Get the 8 carefully selected frames from the transferFrames method
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
