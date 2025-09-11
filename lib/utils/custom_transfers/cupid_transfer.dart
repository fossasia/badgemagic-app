import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferCupidAnimation(
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
  final int logicalFrameCount =
      CupidAnimation.frameCount(badgeWidth, badgeHeight);
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i('Starting Cupid animation transfer...');
  List<Message> cupidFrames = [];
  for (int i = 0; i < hardwareFrameCount; i++) {
    int logicalIdx = ((i * logicalFrameCount) / hardwareFrameCount).floor();
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));
    CupidAnimation().processAnimation(
        badgeHeight, badgeWidth, logicalIdx, frameBitmap, frameBitmap);
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💘 Cupid Frame $i (logic $logicalIdx) hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    cupidFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: cupidFrames);
  logger.i('💘 Cupid Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Cupid animation transfer failed: $e\n$st');
  }
}
