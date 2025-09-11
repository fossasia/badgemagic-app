import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferFishAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  final int hardwareFrameCount = 8;
  final int logicalFrameCount = FishAnimation.framesPerCycle;

  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Fish animation transfer...');

  List<Message> fishFrames = [];

  for (int i = 0; i < hardwareFrameCount; i++) {
    int logicalIdx = ((i * logicalFrameCount) / hardwareFrameCount).floor();

    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    FishAnimation().processAnimation(
        badgeHeight, badgeWidth, logicalIdx, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        '🐟 Fish Frame $i (logic $logicalIdx) hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    fishFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: fishFrames);
  logger.i('🐟 Fish Data object created. Starting transfer...');

  try {
    await transferData(DataTransferManager(data));
    logger.i('🐟 Fish animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ Fish animation transfer failed: $e\n$st');
  }
}
