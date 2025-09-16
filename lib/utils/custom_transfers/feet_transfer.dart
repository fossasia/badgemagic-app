import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

Future<void> customTransferFeetAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int badgeHeight = FeetAnimation.badgeHeight;
  const int badgeWidth = FeetAnimation.badgeWidth;
  const int badgeMaxFrames = 8;
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i('Starting Feet animation transfer...');

  List<int> sampledFrames = List.generate(
      badgeMaxFrames, (i) => FeetAnimation.frameCount - badgeMaxFrames + i);
  logger.i('Sampled frame indices for badge: ${sampledFrames.toString()}');
  if (sampledFrames.isNotEmpty) {
    logger.i(
        'Feet transfer: first frame index = ${sampledFrames.first}, last frame index = ${sampledFrames.last}');
  }

  List<Message> feetFrames = [];
  final feetAnimation = FeetAnimation();

  for (final frame in sampledFrames) {
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    feetAnimation.processAnimation(
      badgeHeight,
      badgeWidth,
      frame,
      List.generate(badgeHeight, (_) => List.filled(badgeWidth, false)),
      frameBitmap,
    );
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '🦶 Sampled Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    feetFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: feetFrames);
  logger.i('🦶 Feet Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Feet animation transfer failed: $e\n$st');
  }
}
