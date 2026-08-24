import 'dart:math';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferPacmanAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  const int pacmanRadius = 4;
  const int foodRadius = 1;
  const int numBlocks = 3;
  const int destructionDuration = 3;

  int pathStart = pacmanRadius + 1;
  int pathEnd = animationBadgeWidth - pacmanRadius - 2;
  int pathLength = pathEnd - pathStart + 1;
  int blockSpacing = (pathLength / (numBlocks + 1)).floor();
  List<int> blockCols =
      List.generate(numBlocks, (b) => pathStart + (b + 1) * blockSpacing);

  List<int> destroyFrames = List.filled(numBlocks, -1);
  List<bool> eatenBlocks = List.filled(numBlocks, false);
  int pacmanRow = animationBadgeHeight ~/ 2;

  final List<List<List<bool>>> frames = [];

  for (int frame = 0; frame < animationFrameCount; frame++) {
    double t = frame / (animationFrameCount - 1);
    int pacmanCol = pathStart + (t * (pathEnd - pathStart)).round();

    double mouthT = (frame * 1.8 + 0.3) / animationFrameCount;
    double minMouth = 3.14 / 10;
    double maxMouth = 3.14 / 1.8;
    double mouthAngle =
        minMouth + (maxMouth - minMouth) * (0.5 * (1 - cos(2 * 3.14 * mouthT)));

    final frameBitmap = blankFrame();

    for (int b = 0; b < numBlocks; b++) {
      if (!eatenBlocks[b] && (pacmanCol - blockCols[b]).abs() <= pacmanRadius) {
        eatenBlocks[b] = true;
        destroyFrames[b] = 0;
        _drawDestroyEffect(frameBitmap, blockCols[b], pacmanRow, 0,
            animationBadgeWidth, animationBadgeHeight);
      }
    }

    for (int b = 0; b < numBlocks; b++) {
      if (destroyFrames[b] > 0 && destroyFrames[b] < destructionDuration) {
        _drawDestroyEffect(frameBitmap, blockCols[b], pacmanRow,
            destroyFrames[b], animationBadgeWidth, animationBadgeHeight);
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
                  drawRow < animationBadgeHeight &&
                  drawCol >= 0 &&
                  drawCol < animationBadgeWidth) {
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
                drawRow < animationBadgeHeight &&
                drawCol >= 0 &&
                drawCol < animationBadgeWidth) {
              frameBitmap[drawRow][drawCol] = true;
            }
          }
        }
      }
    }

    frames.add(frameBitmap);
  }

  {
    final frameBitmap = blankFrame();
    int pacmanCol = pathEnd;
    int pacmanRow = animationBadgeHeight ~/ 2;
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
                drawRow < animationBadgeHeight &&
                drawCol >= 0 &&
                drawCol < animationBadgeWidth) {
              frameBitmap[drawRow][drawCol] = true;
            }
          }
        }
      }
    }
    frames[frames.length - 1] = frameBitmap;
  }

  await sendAnimationFrames(
    label: 'Pacman',
    frames: frames,
    transferData: transferData,
  );
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
