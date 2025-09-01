import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart'; // Import the new EqualizerAnimation

Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.animation,
  6: Mode.snowflake,
  7: Mode.picture,
  8: Mode.laser,
  9: Mode.pacman, // Add this line for Pacman
  10: Mode.chevronleft, // Chevron left mode (now defined in mode.dart)
  11: Mode.diamond, // Diamond animation mode
  12: Mode.brokenhearts, // Broken Hearts mode (use fixed or define if needed)
  13: Mode.cupid, // Cupid mode (use fixed or define if needed)
  14: Mode.feet, // Feet animation mode
};

Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight, // Add superfast for the highest speed
};

class BadgeMessageProvider {
  static final Logger logger = Logger();
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  FileHelper fileHelper = FileHelper();
  Converters converters = Converters();

  Future<Data> getBadgeData(String text, bool flash, bool marq, Speed speed,
      Mode mode, bool isInverted) async {
    List<String> message = await converters.messageTohex(text, isInverted);
    Data data = Data(messages: [
      Message(
        text: message,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
      )
    ]);
    return data;
  }

  Future<Data> generateData(
      String? text,
      bool? flash,
      bool? marq,
      bool? inverted,
      Speed? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData) async {
    if (jsonData != null) {
      return fileHelper.jsonToData(jsonData);
    } else {
      return getBadgeData(text ?? '', flash ?? false, marq ?? false,
          speed ?? Speed.one, mode ?? Mode.left, inverted ?? false);
    }
  }

  Future<void> transferData(DataTransferManager manager) async {
    DateTime now = DateTime.now();
    BleState? state = ScanState(manager: manager);
    while (state != null) {
      state = await state.process();
    }

    logger.d("Time to transfer data is = ${DateTime.now().difference(now)}");
    logger.d(".......Data transfer completed.......");
  }

  Future<void> checkAndTransfer(
      String? text,
      bool? flash,
      bool? marq,
      bool? isInverted,
      int? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData,
      bool isSavedBadge,
      {TextStyle? textStyle}) async {
    if (await FlutterBluePlus.isSupported == false) {
      ToastUtils().showErrorToast('Bluetooth is not supported by the device');
      return;
    }

    if (controllerData.getController().text.isEmpty && isSavedBadge == false) {
      // Allow empty text if Pacman or Fireworks mode is selected
      // Fireworks: Mode.fixed and animation index 19
      bool isFireworks = false;
      try {
        // Try to get animation index from modeValueMap
        int fireworksIndex = 19;
        if (mode == Mode.fixed &&
            modeValueMap.containsKey(fireworksIndex) &&
            modeValueMap[fireworksIndex] == Mode.fixed) {
          isFireworks = true;
        }
      } catch (_) {}
      if (mode != Mode.pacman && !isFireworks) {
        ToastUtils().showErrorToast("Please enter a message");
        return;
      }
    }

    BluetoothAdapterState adapterState =
        await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        ToastUtils().showToast('Turning on Bluetooth...');
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          ToastUtils().showErrorToast('Failed to enable Bluetooth: $e');
          logger.e('Bluetooth turnOn() failed: $e');
          return;
        }

        try {
          adapterState = await FlutterBluePlus.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              ToastUtils().showErrorToast('Bluetooth did not turn on in time.');
              throw Exception('Bluetooth enable timeout');
            },
          );
        } catch (e) {
          logger.e('Error while waiting for Bluetooth to turn on: $e');
          return;
        }
      } else if (Platform.isIOS) {
        ToastUtils().showErrorToast(
          'Bluetooth is OFF. Please enable it from Settings.',
        );

        try {
          adapterState = await FlutterBluePlus.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              ToastUtils().showErrorToast('Bluetooth did not turn on in time.');
              throw Exception('Bluetooth enable timeout');
            },
          );
        } catch (e) {
          logger.e('Error while waiting for Bluetooth to turn on: $e');
          return;
        }
      } else {
        ToastUtils().showErrorToast("Unsupported platform");
        return;
      }
    }

    Data data;
    if (jsonData != null) {
      data = fileHelper.jsonToData(jsonData);
      if (isSavedBadge && data.messages.isNotEmpty) {
        final old = data.messages[0];
        final newMessage = Message(
          text: old.text, // use the already-padded hex string
          flash: old.flash,
          marquee: old.marquee,
          speed: old.speed,
          mode: Mode.animation, // Force seamless marquee
        );
        data = Data(messages: [newMessage, ...data.messages.skip(1)]);
      }
    } else {
      data = await generateData(
          text, flash, marq, isInverted, speedMap[speed], mode, jsonData);
    }

    DataTransferManager manager = DataTransferManager(data);
    await transferData(manager);
  }
}

Future<void> transferFireworksAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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
  await badgeDataProvider.transferData(manager);
  logger.i('💡 Fireworks animation transfer completed successfully!');
}

Future<void> transferBeatingHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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
  await badgeDataProvider.transferData(manager);
  logger.i('💡 Beating Hearts animation transfer completed successfully!');
}

Future<void> transferEmergencyAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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

  // Rotate so frame 6 is sent first, then 7, 0, 1, 2, 3, 4, 5
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
  await badgeDataProvider.transferData(manager);
  logger.i('💡 Emergency animation transfer completed successfully!');
}

/// Transfers the continuous diagonal V animation to the badge hardware.
Future<void> transferDiagonalAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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

  // Empirically determined: the densest diagonal frame (most shapes on badge)
  // for badgeHeight=11, badgeWidth=44, vSpacing=4, speed=0.5 is at frame 38
  const int densestFrameIdx = 38;

  // Generate 8 frames starting from densestFrameIdx for a seamless hardware loop
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
    await badgeDataProvider.transferData(DataTransferManager(data));
    logger.i('V Diagonal animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ V Diagonal animation transfer failed: $e\n$st');
  }
}

/// Transfers the Fish Kiss animation to the badge, even if the homescreen text box is empty.
Future<void> transferFishAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }

  const int badgeHeight = 11;
  const int badgeWidth = 44;
  final int hardwareFrameCount = 8;
  final int logicalFrameCount =
      FishAnimation.framesPerCycle; // Use the framesPerCycle from FishAnimation

  // Use the same speed logic as Diamond/Cupid: always use Speed.eight for seamless animation
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();

  logger.i('Starting Fish animation transfer...');

  List<Message> fishFrames = [];

  for (int i = 0; i < hardwareFrameCount; i++) {
    int logicalIdx = ((i * logicalFrameCount) / hardwareFrameCount).floor();

    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    // Create empty processGrid (not used in FishAnimation but required by interface)
    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    // Process the fish animation frame
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
    await badgeDataProvider.transferData(DataTransferManager(data));
    logger.i('🐟 Fish animation transfer completed successfully!');
  } catch (e, st) {
    logger.e('⛔ Fish animation transfer failed: $e\n$st');
  }
}

Future<void> transferPacmanAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  const int frameCount = 8; // Number of animation frames (max allowed)
  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int pacmanRadius = 4;
  const int foodRadius = 1;
  const int numBlocks = 3;
  const int destructionDuration = 3; // Number of frames for destruction effect

  final logger = Logger();
  logger.i('Starting Pacman animation transfer...');
  // Use the same speed logic as Diamond: always use Speed.eight for seamless feet animation
  final Speed selectedSpeed = Speed.eight;
  logger.i(
      'Pacman transfer: selectedSpeed =  [32m${selectedSpeed.toString()} [0m, hex = ${selectedSpeed.hexValue}');

  List<Message> pacmanFrames = [];

  // Calculate food dot positions (fixed)
  int pathStart = pacmanRadius + 1;
  int pathEnd = badgeWidth - pacmanRadius - 2;
  int pathLength = pathEnd - pathStart + 1;
  int blockSpacing = (pathLength / (numBlocks + 1)).floor();
  List<int> blockCols =
      List.generate(numBlocks, (b) => pathStart + (b + 1) * blockSpacing);

  // Track destruction animation for each block
  List<int> destroyFrames = List.filled(numBlocks, -1);
  List<bool> eatenBlocks = List.filled(numBlocks, false);
  int pacmanRow = badgeHeight ~/ 2;

  // Pacman moves from start to end in 8 steps, mouth opens/closes, eats all dots, and wraps
  for (int frame = 0; frame < frameCount; frame++) {
    logger.i('💡 Generating frame ${frame + 1}');
    // Pacman moves from start to end in frameCount steps
    double t = frame / (frameCount - 1); // Ensure last frame is at pathEnd
    int pacmanCol = pathStart + (t * (pathEnd - pathStart)).round();

    // Mouth animation: smoothly open/close, offset phase for more variety
    double mouthT = (frame * 1.8 + 0.3) /
        frameCount; // slightly more phase offset for smoother mouth
    double minMouth = 3.14 / 10;
    double maxMouth = 3.14 / 1.8;
    double mouthAngle =
        minMouth + (maxMouth - minMouth) * (0.5 * (1 - cos(2 * 3.14 * mouthT)));

    // Build bitmap for this frame
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));

    // Check for eating and trigger destruction
    for (int b = 0; b < numBlocks; b++) {
      if (!eatenBlocks[b] && (pacmanCol - blockCols[b]).abs() <= pacmanRadius) {
        eatenBlocks[b] = true;
        destroyFrames[b] = 0;
        // Draw destruction effect immediately for frame=0
        _drawDestroyEffect(
            frameBitmap, blockCols[b], pacmanRow, 0, badgeWidth, badgeHeight);
      }
    }

    // Draw destruction effect for each block (if not just eaten in this frame)
    for (int b = 0; b < numBlocks; b++) {
      if (destroyFrames[b] > 0 && destroyFrames[b] < destructionDuration) {
        _drawDestroyEffect(frameBitmap, blockCols[b], pacmanRow,
            destroyFrames[b], badgeWidth, badgeHeight);
        destroyFrames[b] = destroyFrames[b] + 1;
      } else if (destroyFrames[b] == 0) {
        // Already drawn above, just increment
        destroyFrames[b] = destroyFrames[b] + 1;
      }
    }

    // Draw food dots (not eaten and not being destroyed)
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

    // Draw Pacman (filled circle with mouth)
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

    // Convert to int bitmap
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    // Convert to hex
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);
    logger.i(
        '💡 Frame $frame hex: ${hexList.join(",")} speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
    pacmanFrames.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed, // Use selected speed
      flash: false,
      marquee: false,
    ));
  }

  // Add a final clean frame (no destruction, no food dots, only Pacman at end)
  {
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    // Pacman at end
    int pacmanCol = pathEnd;
    int pacmanRow = badgeHeight ~/ 2;
    double minMouth = 3.14 / 10;
    double mouthAngle = minMouth;
    // Draw Pacman (closed mouth)
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

  // Create Data object and transfer
  Data data = Data(messages: pacmanFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Pacman animation transfer failed: $e\n$st');
  }
}

Future<void> transferChevronAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  // Bluetooth adapter state check (same as Pacman)
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int frameCount = 8;
  const int badgeHeight = 11;
  const int badgeWidth = 44;

  // Use compact 4x7 arrow, packed tightly
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
  // Use the same speed logic as Diamond: always use Speed.eight for seamless feet animation
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
      speed: selectedSpeed, // Use selected speed
      flash: false,
      marquee: false,
    ));
  }
  Data data = Data(messages: chevronFrames);
  logger.i('💡 Data object created. Starting transfer...');
  try {
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Chevron animation transfer failed: $e\n$st');
  }
}

Future<void> transferDiamondAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int frameCount = 8; // Badge hardware limit
  const int badgeHeight = 11;
  const int badgeWidth = 44;
  const int spawnInterval = 4; // frames between new diamonds
  final Speed selectedSpeed = Speed.eight; // Use max speed
  final logger = Logger();
  logger.i(
      'Diamond transfer (seamless, shifted): selectedSpeed = ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');
  List<Message> diamondFrames = [];
  final DiamondAnimation diamondAnimation = DiamondAnimation();

  // Calculate a cycle length that ensures seamless looping
  // The largest diamond radius is limited by badge size
  final int maxDy = (badgeHeight ~/ 2);
  final int maxDx = (badgeWidth ~/ 4);
  final int maxRadius = max(maxDy, maxDx);
  final int cycleLength = spawnInterval * 2 +
      maxRadius +
      1; // enough for two diamonds to grow and overlap
  // Pick a start index for best seamlessness (e.g., cycleLength - frameCount)
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
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Diamond animation transfer failed: $e\n$st');
  }
}

Future<void> transferBrokenHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int frameCount = 8; // Badge hardware limit
  const int badgeHeight = 11;
  const int badgeWidth = 44;
  final Speed selectedSpeed = Speed.eight; // Use max speed
  final logger = Logger();
  logger.i(
      'Broken Hearts transfer (all pieces fall out): selectedSpeed = ${selectedSpeed.toString()}, hex = ${selectedSpeed.hexValue}');
  List<Message> heartFrames = [];

  // Custom cluster logic for transfer: fewer, larger clusters
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
  final int leftCx = badgeWidth ~/ 4 - heartW ~/ 2 - 2; // shift left by 2
  final int rightCx = 3 * badgeWidth ~/ 4 - heartW ~/ 2 - 2; // shift left by 2
  final int topY = badgeHeight ~/ 2 - heartH ~/ 2;
  final Random rng = Random(12345);

  // Collect all solid pixels for left and right hearts
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

  // Carve into about 6 clusters (fewer, larger pieces)
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
  // Sort so bottom-most clusters fall first
  final paired = List.generate(
    clustersL.length,
    (i) => MapEntry(clustersL[i], clustersR[i]),
  );
  paired.sort((a, b) {
    double ya = a.key.map((p) => p.y).reduce((u, v) => u + v) / a.key.length;
    double yb = b.key.map((p) => p.y).reduce((u, v) => u + v) / b.key.length;
    return yb.compareTo(ya); // descending: larger Y first
  });
  clustersL = paired.map((e) => e.key).toList();
  clustersR = paired.map((e) => e.value).toList();

  final int N = clustersL.length; // ensure all clusters fall out

  // For transfer, sample the first 8 frames of the cycle
  for (int frame = 0; frame < frameCount; frame++) {
    int logicFrame = frame; // first 8 frames
    int fallStep = 3; // move clusters down 3 rows per frame
    List<List<bool>> frameBitmap =
        List.generate(badgeHeight, (_) => List.filled(badgeWidth, false));
    if (frame < frameCount - 1) {
      // Draw falling clusters for frames 0-6
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
    } // else: frameBitmap remains blank for the last frame
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
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Broken Hearts animation transfer failed: $e\n$st');
  }
}

Future<void> transferFeetAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return;
  }
  const int badgeHeight = FeetAnimation.badgeHeight;
  const int badgeWidth = FeetAnimation.badgeWidth;
  const int badgeMaxFrames = 8;
  // Use the same speed logic as Diamond: always use Speed.eight for seamless feet animation
  final Speed selectedSpeed = Speed.eight;
  final logger = Logger();
  logger.i('Starting Feet animation transfer...');

  // Find the best 8-frame segment that does not cross the wrap boundary
  // This assumes wrap occurs at frame 20 (FeetAnimation.frameCount)
  // So, sample frames 12-19 (last 8) to avoid the step-back glitch
  List<int> sampledFrames = List.generate(
      badgeMaxFrames, (i) => FeetAnimation.frameCount - badgeMaxFrames + i);
  logger.i(
      'Sampled frame indices for badge: \u001b[34m${sampledFrames.toString()}\u001b[0m');
  if (sampledFrames.isNotEmpty) {
    logger.i(
        'Feet transfer: first frame index = \u001b[35m${sampledFrames.first}\u001b[0m, last frame index = \u001b[35m${sampledFrames.last}\u001b[0m');
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
        '🦶 Sampled Frame $frame hex: \x1b[32m${hexList.join(",")}\x1b[0m speed: ${selectedSpeed.toString()} (hex: ${selectedSpeed.hexValue})');
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
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Feet animation transfer failed: $e\n$st');
  }
}

Future<void> transferCupidAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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
  // Use the same speed logic as Diamond: always use Speed.eight for seamless feet animation
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
    await badgeDataProvider.transferData(DataTransferManager(data));
  } catch (e, st) {
    logger.e('⛔ Cupid animation transfer failed: $e\n$st');
  }
}

List<List<int>> boolToIntBitmap(List<List<bool>> bitmap) {
  return bitmap.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
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

/// Transfers the Equalizer animation to the badge hardware.
Future<void> transferEqualizerAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
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

  //  Create the animation object *before* the loop because it's stateful.
  final equalizerAnimation = EqualizerAnimation();

  for (int i = 0; i < hardwareFrameCount; i++) {
    List<List<bool>> frameBitmap = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    List<List<bool>> processGrid = List.generate(
        badgeHeight, (_) => List.generate(badgeWidth, (_) => false));

    equalizerAnimation.processAnimation(
        badgeHeight, badgeWidth, i, processGrid, frameBitmap);

    // Convert the boolean bitmap to a hex string
    List<List<int>> intBitmap = boolToIntBitmap(frameBitmap);
    List<String> hexList = Converters.convertBitmapToLEDHex(intBitmap, false);

    logger.i('📊 Equalizer Frame $i hex: ${hexList.join(",")}');

    equalizerFrames.add(Message(
      text: hexList,
      mode: Mode.fixed, // Each frame is sent as a fixed image
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  Data data = Data(messages: equalizerFrames);
  DataTransferManager manager = DataTransferManager(data);
  await badgeDataProvider.transferData(manager);
  logger.i('💡 Equalizer animation transfer completed successfully!');
}
