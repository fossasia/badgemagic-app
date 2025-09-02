import 'dart:math';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';

Future<void> customTransferFireworksAnimation(
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

  logger.i('Starting Fireworks animation transfer...');

  List<Message> frames = [];
  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));
    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    FireworksAnimation()
        .processAnimation(badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i(
        'Fireworks Frame $i hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');

    frames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: frames);
  DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 Fireworks animation transfer completed successfully!');
}

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

Future<void> customTransferPacmanAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  const int frameCount = 8;
  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int pacmanRadius = 4;
  const int foodRadius = 1;
  const int numBlocks = 3;
  const int destructionDuration = 3;

  final logger = Logger();
  logger.i('Starting Pacman animation transfer...');
  final Speed selectedSpeed = Speed.eight;
  logger.i(
      'Pacman transfer: selectedSpeed =  ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');

  List<Message> pacmanFrames = [];

  int pathStart = pacmanRadius + 1;
  int pathEnd = badgeWidth - pacmanRadius - 2;
  int pathLength = pathEnd - pathStart + 1;
  int blockSpacing = (pathLength / (numBlocks + 1)).floor();
  List<int> blockCols =
      List.generate(numBlocks, (b) => pathStart + (b + 1) * blockSpacing);

  List<int> destroyFrames = List.filled(numBlocks, -1);
  List<bool> eatenBlocks = List.filled(numBlocks, false);
  int pacmanRow = badgeHeight ~/ 2;

  for (int frame = 0; frame < frameCount; frame++) {
    logger.i('💡 Generating frame ${frame + 1}');
    double t = frame / (frameCount - 1);
    int pacmanCol = pathStart + (t * (pathEnd - pathStart)).round();

    double mouthT = (frame * 1.8 + 0.3) / frameCount;
    double minMouth = 3.14 / 10;
    double maxMouth = 3.14 / 1.8;
    double mouthAngle =
        minMouth + (maxMouth - minMouth) * (0.5 * (1 - cos(2 * 3.14 * mouthT)));

    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));

    for (int b = 0; b < numBlocks; b++) {
      if (!eatenBlocks[b] && (pacmanCol - blockCols[b]).abs() <= pacmanRadius) {
        eatenBlocks[b] = true;
        destroyFrames[b] = 0;
        _drawDestroyEffect(
            frameBitmap, blockCols[b], pacmanRow, 0, badgeWidth, badgeHeight);
      }
    }

    for (int b = 0; b < numBlocks; b++) {
      if (destroyFrames[b] > 0 && destroyFrames[b] < destructionDuration) {
        _drawDestroyEffect(frameBitmap, blockCols[b], pacmanRow,
            destroyFrames[b], badgeWidth, badgeHeight);
        destroyFrames[b] = destroyFrames[b] + 1;
      } else if (destroyFrames[b] == 0) {
        destroyFrames[b] = destroyFrames[b] + 1;
      }
    }

    for (int b = 0; b < numBlocks; b++) {
      if (!eatenBlocks[b] && destroyFrames[b] < 0) {
        for (int y = -foodRadius; y <= foodRadius; y++) {
          for (int x = -foodRadius; x <= foodRadius; x++) {
            if (x * x + y * y <= foodRadius * foodRadius) {
              int drawRow = pacmanRow + y;
              int drawCol = blockCols[b] + x;
              if (drawRow >= 0 &&
                  drawRow < badgeHeight &&
                  drawCol >= 0 &&
                  drawCol < badgeWidth) {
                frameBitmap[drawRow][drawCol] = true;
              }
            }
          }
        }
      }
    }

    for (int y = -pacmanRadius; y <= pacmanRadius; y++) {
      for (int x = -pacmanRadius; x <= pacmanRadius; x++) {
        double angle = atan2(y.toDouble(), x.toDouble());
        double dist = sqrt(x * x + y * y);
        if (dist <= pacmanRadius) {
          if (!(angle.abs() < mouthAngle / 2 && x > 0)) {
            int drawRow = pacmanRow + y;
            int drawCol = pacmanCol + x;
            if (drawRow >= 0 &&
                drawRow < badgeHeight &&
                drawCol >= 0 &&
                drawCol < badgeWidth) {
              frameBitmap[drawRow][drawCol] = true;
            }
          }
        }
      }
    }

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💡 Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    pacmanFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  {
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    int pacmanCol = pathEnd;
    int pacmanRow = badgeHeight ~/ 2;
    double minMouth = 3.14 / 10;
    double mouthAngle = minMouth;
    for (int y = -pacmanRadius; y <= pacmanRadius; y++) {
      for (int x = -pacmanRadius; x <= pacmanRadius; x++) {
        double angle = atan2(y.toDouble(), x.toDouble());
        double dist = sqrt(x * x + y * y);
        if (dist <= pacmanRadius) {
          if (!(angle.abs() < mouthAngle / 2 && x > 0)) {
            int drawRow = pacmanRow + y;
            int drawCol = pacmanCol + x;
            if (drawRow >= 0 &&
                drawRow < badgeHeight &&
                drawCol >= 0 &&
                drawCol < badgeWidth) {
              frameBitmap[drawRow][drawCol] = true;
            }
          }
        }
      }
    }
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    pacmanFrames[pacmanFrames.length - 1] = Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    );
  }

  logger.i('💡 Total frames generated: ${pacmanFrames.length}');

  Data data = Data(messages: pacmanFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Pacman animation transfer failed: $e\n$st');
  }
}

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
  final int maxRadius = max(maxDy, maxDx);
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

  List<List<int>>? firstIntBitmap;
  List<List<int>>? lastIntBitmap;
  List<String>? firstHexList;
  List<String>? lastHexList;
  int i = 0;
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
    if (i == 0) {
      firstIntBitmap = intBitmap;
      firstHexList = hexList;
    }
    if (i == sampledFrames.length - 1) {
      lastIntBitmap = intBitmap;
      lastHexList = hexList;
    }
    logger.i(
        '🦶 Sampled Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    feetFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
    i++;
  }
  if (firstIntBitmap != null && lastIntBitmap != null) {
    logger.w('First frame intBitmap: $firstIntBitmap');
    logger.w('Last frame intBitmap: $lastIntBitmap');
    logger.w('First frame hex: $firstHexList');
    logger.w('Last frame hex: $lastHexList');
  }
  Data data = Data(messages: feetFrames);
  logger.i('🦶 Feet Data object created. Starting transfer...');
  try {
    await transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Feet animation transfer failed: $e\n$st');
  }
}

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

Future<void> customTransferEqualizerAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int hardwareFrameCount = 8; // The badge can store up to 8 frames
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Equalizer animation transfer...');

  List<Message> equalizerFrames = [];

  final equalizerAnimation = EqualizerAnimation();

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    equalizerAnimation.processAnimation(
        badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i('📊 Equalizer Frame $i hex: ${hexList.join(",")}');

    equalizerFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: equalizerFrames);
  DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 Equalizer animation transfer completed successfully!');
}

List<List<int>> boolToIntBitmap(List<List<bool>> bitmap) {
  return bitmap.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
}

/// Transfers the Equalizer animation to the badge hardware using a callback,
/// consistent with other customTransfer* helpers.
Future<void> customTransferEqualizerAnimation(
    Future<void> Function(DataTransferManager) transferData,
    int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int hardwareFrameCount = 8; // The badge can store up to 8 frames
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Equalizer animation transfer...');

  List<Message> equalizerFrames = [];

  final equalizerAnimation = EqualizerAnimation();

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    equalizerAnimation.processAnimation(
        badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i('📊 Equalizer Frame $i hex: ${hexList.join(",")}');

    equalizerFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: equalizerFrames);
  DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 Equalizer animation transfer completed successfully!');
}

void _drawDestroyEffect(
    List<List<bool>> canvas, int cx, int cy, int frame, int w, int h) {
  int length = frame + 1;
  List<List<int>> dirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1]
  ];
  for (var d in dirs) {
    for (int i = 1; i <= length; i++) {
      int px = cx + d[0] * i;
      int py = cy + d[1] * i;
      if (py >= 0 && py < h && px >= 0 && px < w) {
        canvas[py][px] = true;
      }
    }
  }
}
