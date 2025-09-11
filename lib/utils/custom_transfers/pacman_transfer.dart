import 'dart:math';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/utils/custom_transfers/common.dart';
import 'package:logger/logger.dart';

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
