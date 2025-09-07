import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferBeatingHeartsAnimation(
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

  logger.i('Starting Beating Hearts animation transfer...');

  List<Message> heartFrames = [];

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));
    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    BeatingHeartsAnimation()
        .processAnimation(badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        'BeatingHearts Frame $i hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    heartFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: heartFrames);
  DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 Beating Hearts animation transfer completed successfully!');
}
