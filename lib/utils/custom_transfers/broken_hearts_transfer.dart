import 'dart:math';
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

Future<void> customTransferBrokenHeartsAnimation(
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
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i(
      'Broken Hearts transfer (all pieces fall out): selectedSpeed = ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');
  List<Message> heartFrames = [];

  final List<List<int>> heartShape = [
    [0, 0, 1, 1, 0, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];
  final int heartW = heartShape[0].length;
  final int heartH = heartShape.length;
  final int leftCx = badgeWidth ~/ 4 - heartW ~/ 2 - 2;
  final int rightCx = 3 * badgeWidth ~/ 4 - heartW ~/ 2 - 2;
  final int topY = badgeHeight ~/ 2 - heartH ~/ 2;
  final Random rng = Random(12345);

  final pixelsL = <Point<int>>[];
  final pixelsR = <Point<int>>[];
  for (int y = 0; y < heartH; y++) {
    for (int x = 0; x < heartW; x++) {
      if (heartShape[y][x] == 1) {
        pixelsL.add(Point(leftCx + x, topY + y));
        pixelsR.add(Point(rightCx + x, topY + y));
      }
    }
  }

  int numClusters = 6;
  int clusterSize = (pixelsL.length / numClusters).ceil();
  List<List<Point<int>>> clustersL = [];
  List<List<Point<int>>> clustersR = [];
  var tempL = List<Point<int>>.from(pixelsL);
  var tempR = List<Point<int>>.from(pixelsR);
  while (tempL.isNotEmpty) {
    int size = min(clusterSize, tempL.length);
    final clusterL = <Point<int>>[];
    final clusterR = <Point<int>>[];
    for (int i = 0; i < size; i++) {
      int idx = rng.nextInt(tempL.length);
      clusterL.add(tempL.removeAt(idx));
      clusterR.add(tempR.removeAt(idx));
    }
    clustersL.add(clusterL);
    clustersR.add(clusterR);
  }
  final paired = List.generate(
    clustersL.length,
    (i) => MapEntry(clustersL[i], clustersR[i]),
  );
  paired.sort((a, b) {
    double ya = a.key.map((p) => p.y).reduce((u, v) => u + v) / a.key.length;
    double yb = b.key.map((p) => p.y).reduce((u, v) => u + v) / b.key.length;
    return yb.compareTo(ya);
  });
  clustersL = paired.map((e) => e.key).toList();
  clustersR = paired.map((e) => e.value).toList();

  final int N = clustersL.length;

  for (int frame = 0; frame < frameCount; frame++) {
    int logicFrame = frame;
    int fallStep = 3;
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    if (frame < frameCount - 1) {
      for (int i = 0; i < N; i++) {
        bool isFalling = logicFrame >= i;
        int dy = (logicFrame - i) * fallStep;
        for (var pt in clustersL[i]) {
          int y = isFalling ? pt.y + dy : pt.y;
          if (y >= 0 && y < badgeHeight) frameBitmap[y][pt.x] = true;
        }
        for (var pt in clustersR[i]) {
          int y = isFalling ? pt.y + dy : pt.y;
          if (y >= 0 && y < badgeHeight) frameBitmap[y][pt.x] = true;
        }
      }
    }
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💡 Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    heartFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: heartFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Broken Hearts animation transfer failed: $e\n$st');
  }
}
