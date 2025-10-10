import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferEmergencyAnimation(
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

  logger.i('Starting Emergency animation transfer...');

  List<Message> emergencyFrames = [];

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));
    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    EmergencyAnimation()
        .processAnimation(badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        'Emergency Frame $i hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    emergencyFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  List<Message> rotatedFrames = [
    emergencyFrames[6],
    emergencyFrames[7],
    emergencyFrames[0],
    emergencyFrames[1],
    emergencyFrames[2],
    emergencyFrames[3],
    emergencyFrames[4],
    emergencyFrames[5],
  ];

  Data data = Data(messages: rotatedFrames);
  DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 Emergency animation transfer completed successfully!');
}
