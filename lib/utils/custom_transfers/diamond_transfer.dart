import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferDiamondAnimation(
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
  const int spawnInterval = 4;
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i(
      'Diamond transfer (seamless, shifted): selectedSpeed = ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');
  List<Message> diamondFrames = [];
  final DiamondAnimation diamondAnimation = DiamondAnimation();

  final int maxDy = (badgeHeight ~/ 2);
  final int maxDx = (badgeWidth ~/ 4);
  final int maxRadius = maxDy > maxDx ? maxDy : maxDx;
  final int cycleLength = spawnInterval * 2 + maxRadius + 1;
  final int startIndex = cycleLength - frameCount;

  for (int frame = 0; frame < frameCount; frame++) {
    int animationIndex = (startIndex + frame) % cycleLength;
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    diamondAnimation.processAnimation(
      badgeHeight,
      badgeWidth,
      animationIndex,
      List.generate(badgeHeight, (_) => List.filled(badgeWidth, false)),
      frameBitmap,
    );
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💡 Frame $frame (logic index $animationIndex) hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    diamondFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: diamondFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Diamond animation transfer failed: $e\n$st');
  }
}
