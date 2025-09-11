import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferChevronAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int frameCount = 8;
  const int badgeHeight = 11;
  const int badgeWidth = 44;

  int arrowWidth = 4;
  int arrowHeight = 7;
  List<List<bool>> arrow = [
    [false, false, false, true],
    [false, false, true, false],
    [false, true, false, false],
    [true, false, false, false],
    [false, true, false, false],
    [false, false, true, false],
    [false, false, false, true],
  ];
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i(
      'Chevron transfer: selectedSpeed = ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');
  List<Message> chevronFrames = [];
  for (int frame = 0; frame < frameCount; frame++) {
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    int offset = frame % arrowWidth;
    int arrowTop = (badgeHeight - arrowHeight) ~/ 2;
    for (int arrowIdx = 0;
        arrowIdx < (badgeWidth / arrowWidth).ceil() + 2;
        arrowIdx++) {
      int startCol = badgeWidth - offset - arrowIdx * arrowWidth;
      for (int y = 0; y < arrowHeight; y++) {
        for (int x = 0; x < arrowWidth; x++) {
          int row = arrowTop + y;
          int col = startCol + x;
          if (row >= 0 &&
              row < badgeHeight &&
              col >= 0 &&
              col < badgeWidth &&
              arrow[y][x]) {
            frameBitmap[row][col] = true;
          }
        }
      }
    }
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💡 Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    chevronFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: chevronFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Chevron animation transfer failed: $e\n$st');
  }
}
