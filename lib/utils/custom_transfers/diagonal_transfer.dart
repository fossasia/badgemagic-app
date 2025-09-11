import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferDiagonalAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int hardwareFrameCount = 8;
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger
      .i('Starting Diagonal animation transfer for seamless hardware loop...');

  List<Message> diagonalFrames = [];

  const int densestFrameIdx = 38;

  for (int i = 0; i < hardwareFrameCount; i++) {
    int logicalIdx = densestFrameIdx + i;
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));
    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    DiagonalAnimation().processAnimation(
        badgeHeight, badgeWidth, logicalIdx, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        'V Diagonal Frame $i (logic $logicalIdx) hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    diagonalFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: diagonalFrames);
  logger.i('V Diagonal Data object created. Starting transfer...');

  try {
    await transferData(DataTransferManager(data));
    logger.i('V Diagonal animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ V Diagonal animation transfer failed: $e\n$st');
  }
}
